//
//  LocalNetwork.m
//  sniffer
//
//  Created by Rex Sheng on 1/20/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "LocalNetwork.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#include <netdb.h>
#import "SimplePing.h"
#import "SimpleMacAddress.h"
#import "GCDAsyncSocket.h"

@interface LocalNetwork () <SimplePingDelegate, GCDAsyncSocketDelegate>
@property (nonatomic, strong, readwrite) NSMutableArray *localDevices;
@end

@implementation LocalNetwork
{
	in_addr_t local_addr, mask, wildcard, broadcast, start_addr, end_addr;
	NSMutableArray *sockets;
	NSMutableArray *pingers;
	NSMutableArray *_localDevices;
}

@synthesize localDevices = _localDevices;

+ (NSString *)readableIPv4Address:(in_addr_t)address
{
	unsigned int a = (address & 0xFF000000) >> 24;
	unsigned int b = (address & 0x00FF0000) >> 16;
	unsigned int c = (address & 0x0000FF00) >> 8;
	unsigned int d = address & 0x000000FF;
	return [NSString stringWithFormat:@"%d.%d.%d.%d", d, c, b, a];
}

- (void)detectIPv4Address
{
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	
	if (success == 0) {
		temp_addr = interfaces;
		
		while (temp_addr != NULL) {
			// check if interface is en0 which is the wifi connection on the iPhone
			if (temp_addr->ifa_addr->sa_family == AF_INET) {
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
					local_addr = (((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr).s_addr;
					mask = (((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr).s_addr;
					wildcard = ~mask;
					broadcast = local_addr | wildcard;
					end_addr = broadcast - (1 << 24);
					start_addr = broadcast - wildcard + (1 << 24);
					NSLog(@"broadcast %@", [LocalNetwork readableIPv4Address:broadcast]);
					NSLog(@"start_addr %@", [LocalNetwork readableIPv4Address:start_addr]);
					NSLog(@"end_addr %@", [LocalNetwork readableIPv4Address:end_addr]);
				}
			}
			temp_addr = temp_addr->ifa_next;
		}
	}
	freeifaddrs(interfaces);
}

- (void)scanDevices
{
	[self detectIPv4Address];
	pingers = [NSMutableArray array];
	_localDevices = [NSMutableArray array];
	unsigned int start, end;
	unsigned int(^reverse)(in_addr_t addr) = ^(in_addr_t addr) {
		unsigned int a = (addr & 0xFF000000) >> 24;
		unsigned int b = (addr & 0x00FF0000) >> 16;
		unsigned int c = (addr & 0x0000FF00) >> 8;
		unsigned int d = addr & 0x000000FF;
		return d << 24 | c << 16 | b << 8 | a;
	};
	start = reverse(start_addr);
	end = reverse(end_addr);
	for (unsigned int i = start; i <= end; i++) {
		NSString *hostName = [LocalNetwork readableIPv4Address:reverse(i)];
		SimplePing *pinger = [SimplePing simplePingWithHostName:hostName];
		pinger.delegate = self;
		[pinger start];
		[pingers addObject:pinger];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self removePinger:pinger];
		});
	}
}

// When the pinger starts, send the ping immediately
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
	[pinger sendPingWithData:nil];
}

- (void)removePinger:(SimplePing *)pinger
{
	[pingers removeObject:pinger];
	if (!pingers.count) {
		[self.delegate localNetworkDidFinish];
	}
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
	[_localDevices addObject:pinger.hostName];
	const struct sockaddr_in *address = [pinger.hostAddress bytes];
	
	NSLog(@"%@ MAC %@", pinger.hostName, [SimpleMacAddress ip2mac:address->sin_addr.s_addr]);
	[self.delegate localNetworkDidFindDevice:pinger.hostName];
}

- (void)portsScan:(NSString *)ip
{
	sockets = [NSMutableArray array];
	
	dispatch_queue_t mainQueue = dispatch_get_main_queue();
	
	GCDAsyncSocket *asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
	static NSMutableIndexSet *ports;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		ports = [NSMutableIndexSet indexSet];
		[ports addIndexesInRange:NSMakeRange(0, 65536)];
	});
	
	[ports enumerateIndexesUsingBlock:^(NSUInteger port, BOOL *stop) {
		[asyncSocket connectToHost:ip onPort:port withTimeout:1 error:nil];
		[sockets addObject:asyncSocket];
	}];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	NSLog(@"%@:%d ok!", host, port);
	[sock disconnect];
	[self.delegate localNetworkDidFindDevice:host port:port];
}

- (void)removeSocket:(GCDAsyncSocket *)socket
{
	if ([sockets indexOfObject:socket] != NSNotFound) {
		[sockets removeObject:socket];
		if (!sockets.count) {
			[self.delegate localNetworkDidFinishPortScan];
		}
	}
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
	[self removeSocket:sock];
	return 0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	[self removeSocket:sock];
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
	[self removeSocket:sock];
	return 0;
}

@end
