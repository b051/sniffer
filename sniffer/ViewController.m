//
//  ViewController.m
//  sniffer
//
//  Created by Rex Sheng on 1/20/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "ViewController.h"
#import "LocalNetwork.h"

@interface ViewController () <LocalNetworkDelegate, NSNetServiceBrowserDelegate>

@end

@implementation ViewController
{
	LocalNetwork *network;
}
//NSString * runCommand(NSString* c) {
//	
//	NSString* outP; FILE *read_fp;  char buffer[BUFSIZ + 1];
//	int chars_read; memset(buffer, '\0', sizeof(buffer));
//	read_fp = popen(c.UTF8String, "r");
//	if (read_fp != NULL) {
//		chars_read = fread(buffer, sizeof(char), BUFSIZ, read_fp);
//		if (chars_read > 0) outP = [NSString stringWithUTF8String:buffer];
//		pclose(read_fp);
//	}
//	return outP;
//}

- (void)viewDidLoad
{
	[super viewDidLoad];
	network = [LocalNetwork new];
	network.delegate = self;
	[network scanDevices];
//	NSLog(@"%@", runCommand(@"ls -la /"));
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
	NSLog(@"%@", domainString);
}

#pragma mark - LocalNetworkDelegate
- (void)localNetworkDidFinish
{
	NSLog(@"no more devices.");
	NSString *ip = network.localDevices.lastObject;
	NSLog(@"detecting ports on %@", ip);
	[network portsScan:ip];
}

- (void)localNetworkDidFindDevice:(NSString *)ip
{
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
