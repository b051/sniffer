//
//  LocalDevice.m
//  sniffer
//
//  Created by Rex Sheng on 1/23/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "LocalDevice.h"
#import "GCDAsyncSocket.h"
#import "Manufacturer.h"
#import "SimpleMacAddress.h"

@interface LocalDevice () <GCDAsyncSocketDelegate>
@end

@implementation LocalDevice
{
	NSMutableArray *sockets;
}

- (void)addService:(NSString *)type port:(NSInteger)port
{
	if (!self.ports) {
		self.ports = [NSMutableDictionary dictionary];
	}
	self.ports[@(port)] = type;
}

- (NSString *)description
{
	NSMutableString *string = [NSMutableString stringWithString:@"device: "];
	[string appendString:self.name ?: @"(n/a)"];
	[string appendString:@"\n"];
	if (self.hostName) {
		[string appendString:self.hostName];
	}
	else {
		[string appendString:self.ipv4];
	}
	[string appendString:@" "];
	if (self.macAddress) {
		[string appendFormat:@"(%@)", self.macAddress];
	}
	[string appendString:@"\nipv4: "];
	[string appendString:self.ipv4];
	if (self.ipv6) {
		[string appendFormat:@", ipv6: %@", self.ipv6];
	}
	if (self.ports) {
		[string appendFormat:@" ports: %@", self.ports];
	}
	if (self.manufacturer) {
		[string appendFormat:@"\n%@", self.manufacturer];
	}
	return string;
}

- (void)startPortsScan
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
		[asyncSocket connectToHost:self.ipv4 onPort:port withTimeout:1 error:nil];
		[sockets addObject:asyncSocket];
	}];
}

- (void)setLocal_addr:(in_addr_t)local_addr
{
	_local_addr = local_addr;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *macAddress = [SimpleMacAddress ip2mac:local_addr];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.macAddress = macAddress;
		});
	});
}

- (void)setMacAddress:(NSString *)macAddress
{
	_macAddress = macAddress;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *manufacturer = [Manufacturer mac2manufacturer:macAddress];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.manufacturer = manufacturer;
		});
	});
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	NSLog(@"%@:%d ok!", host, port);
	[sock disconnect];
	if (!self.ports) {
		self.ports = [NSMutableDictionary dictionary];
	}
	self.ports[@(port)] = @"";
}

- (void)removeSocket:(GCDAsyncSocket *)socket
{
	if ([sockets indexOfObject:socket] != NSNotFound) {
		[sockets removeObject:socket];
		if (!sockets.count) {
			[self.delegate deviceDidFinishPortScan:self];
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
