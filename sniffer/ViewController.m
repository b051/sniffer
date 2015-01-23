//
//  ViewController.m
//  sniffer
//
//  Created by Rex Sheng on 1/20/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "ViewController.h"
#import "LocalNetwork.h"

@interface ViewController () <LocalNetworkDelegate, NSNetServiceDelegate>

@end

@implementation ViewController
{
	LocalNetwork *network;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	network = [LocalNetwork new];
	network.delegate = self;
	[network scanDevices];
}

#pragma mark - LocalNetworkDelegate
- (void)localNetworkDidFinish
{
	for (id device in network.localDevices) {
		NSLog(@"%@", device);
	}
}

- (void)localNetworkDidFindDevice:(NSString *)ip
{
}

@end
