//
//  BonjourBrowser.m
//  sniffer
//
//  Created by Rex Sheng on 1/23/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "BonjourBrowser.h"

@interface BonjourBrowser () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@end

@implementation BonjourBrowser
{
	NSMutableArray *browsers;
	NSMutableArray *services;
}

- (void)start
{
	browsers = [NSMutableArray array];
	services = [NSMutableArray array];
	for (NSString *name in @[@"music", @"acp-sync", @"adisk", @"dlna", @"airplay", @"airkan", @"airport", @"appletv-v2",
							 @"home-sharing", @"icloud-ds", @"sleep-proxy", @"whats-my-name", @"raop",
							 @"afpovertcp", @"eppc", @"rfb", @"smb", @"sftp-ssh", @"ssh",
							 @"rc", @"http", @"rfb", @"beo-settings"]) {
		NSNetServiceBrowser *browser = [NSNetServiceBrowser new];
		browser.delegate = self;
		[browser searchForServicesOfType:[NSString stringWithFormat:@"_%@._tcp.", name] inDomain:@"local."];
		[browsers addObject:browser];
	}
	NSNetServiceBrowser *b3 = [NSNetServiceBrowser new];
	b3.delegate = self;
	[b3 searchForBrowsableDomains];
	[browsers addObject:b3];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
	NSLog(@"find domain %@", domainString);
	if (!moreComing) {
		[browsers removeObject:aNetServiceBrowser];
	}
}

/* Sent to the NSNetServiceBrowser instance's delegate for each service discovered. If there are more services, moreComing will be YES. If for some reason handling discovered services requires significant processing, accumulating services until moreComing is NO and then doing the processing in bulk fashion may be desirable.
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	aNetService.delegate = self;
	[aNetService resolveWithTimeout:2];
	[services addObject:aNetService];
	if (!moreComing) {
		[browsers removeObject:aNetServiceBrowser];
	}
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	[services removeObject:sender];
	if (!services.count) {
		[self.delegate bonjourBrowserDidFinish];
	}
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	[self.delegate bonjourBrowserDidFindService:sender];
	[services removeObject:sender];
	if (!services.count) {
		[self.delegate bonjourBrowserDidFinish];
	}
}

@end
