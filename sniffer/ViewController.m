//
//  ViewController.m
//  sniffer
//
//  Created by Rex Sheng on 1/20/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "ViewController.h"
#import "LocalNetwork.h"

@interface ViewController () <LocalNetworkDelegate>

@end

@implementation ViewController
{
	LocalNetwork *network;
	NSArray *ips;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	network = [LocalNetwork new];
	network.delegate = self;
	[network scanDevices];
}

- (void)localNetworkDidFinish
{
	NSLog(@"no more devices.");
	NSString *ip = network.localDevices.lastObject;
	NSLog(@"detecting ports on %@", ip);
	[network portsScan:ip];
}

- (void)localNetworkDidFindDevice:(NSString *)ip
{
	NSLog(@"found device at %@", ip);
}

- (void)localNetworkDidFindDevice:(NSString *)ip port:(int16_t)port
{
	NSLog(@"found port %d", port);
}

- (void)localNetworkDidFinishPortScan
{
	NSLog(@"no more ports");
}

@end
