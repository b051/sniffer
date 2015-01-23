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
#import "BonjourBrowser.h"
#import "LocalDevice.h"

@interface LocalNetwork () <SimplePingDelegate, GCDAsyncSocketDelegate, BonjourBrowserDelegate>
@property (nonatomic, strong, readwrite) NSMutableArray *localDevices;
@end

@implementation LocalNetwork
{
	in_addr_t local_addr, mask, wildcard, broadcast, start_addr, end_addr;
	NSMutableArray *sockets;
	NSMutableArray *pingers;
	NSMutableArray *_localDevices;
	BonjourBrowser *browser;
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

- (LocalDevice *)deviceByAddress:(NSData *)addressData
{
	const struct sockaddr *address = [addressData bytes];
	if (address->sa_family == AF_INET) {
		in_addr_t addr = (((struct sockaddr_in *)address)->sin_addr).s_addr;
		NSString *ipv4 = [LocalNetwork readableIPv4Address:addr];
		for (LocalDevice *device in self.localDevices) {
			if ([device.ipv4 isEqualToString:ipv4])
				return device;
		}
	}
	return nil;
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
				NSString *wifi = @"en0";
#if TARGET_IPHONE_SIMULATOR
				wifi = @"en1";
#endif
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:wifi]) {
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
		browser = [BonjourBrowser new];
		browser.delegate = self;
		[browser start];
	}
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
	LocalDevice *device = [LocalDevice new];
	device.ipv4 = pinger.hostName;
	device.addressv4 = pinger.hostAddress;
	[_localDevices addObject:device];
	const struct sockaddr_in *address = [pinger.hostAddress bytes];
	device.macAddress = [SimpleMacAddress ip2mac:address->sin_addr.s_addr];
	[self.delegate localNetworkDidFindDevice:pinger.hostName];
}

- (void)bonjourBrowserDidFinish
{
	[self.delegate localNetworkDidFinish];
}

- (void)bonjourBrowserDidFindService:(NSNetService *)service
{
	LocalDevice *device;
	for (NSData *addressData in service.addresses) {
		if (device) {
			device.addressv6 = addressData;
		}
		if (!device) {
			device = [self deviceByAddress:addressData];
		}
	}
	static NSArray *servicesPredictableForName;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		servicesPredictableForName = @[@"_sftp-ssh._tcp.", @"_airplay._tcp.", @"_airport._tcp.", @"_whats-my-name._tcp.", @"_ssh._tcp.", @"_smb._tcp.", @"_afpovertcp._tcp.", @"_adisk._tcp."];
	});
	if (device) {
		if (!device.name || [servicesPredictableForName containsObject:service.type]) {
			device.name = service.name;
			if ([service.type isEqualToString:@"_raop._tcp."]) {
				NSInteger index = [device.name rangeOfString:@"@"].location;
				if (index != NSNotFound) {
					device.name = [device.name substringFromIndex:index + 1];
				}
			}
		}
		if (!device.hostName) {
			device.hostName = service.hostName;
		}
	}
	else {
		NSLog(@"missing service %@", service);
	}
	[device addService:service.type port:service.port];
}

@end
