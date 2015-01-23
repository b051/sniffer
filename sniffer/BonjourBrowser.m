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
	//https://developer.apple.com/library/mac/qa/qa1312/_index.html
	NSArray *smallset = @[@"whats-my-name", @"airport", @"airplay", @"raop", @"smb", @"http", @"ssh", @"ipp", @"eppc", @"afpovertcp"];
	__unused NSArray *largeset = @[@"music", @"acp-sync", @"adisk", @"dlna", @"airplay", @"airkan", @"airport", @"appletv-v2",
								   @"home-sharing", @"icloud-ds", @"sleep-proxy", @"printer", @"workstation", @"nfs", @"webdav", @"whats-my-name", @"raop",
								   @"afpovertcp", @"eppc", @"rfb", @"smb", @"sftp-ssh", @"ssh", @"https", @"rdp", @"webdavs",
								   @"rc", @"http", @"rfb", @"daap", @"dpap", @"ipp", @"telnet"];
	for (NSString *name in smallset) {
		NSNetServiceBrowser *browser = [NSNetServiceBrowser new];
		browser.delegate = self;
		[browser searchForServicesOfType:[NSString stringWithFormat:@"_%@._tcp.", name] inDomain:@"local."];
		[browsers addObject:browser];
	}
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		for (NSNetServiceBrowser *browser in [browsers copy]) {
			[browser stop];
			[browsers removeObject:browser];
		}
	});
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
	NSLog(@"%@", errorDict);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	aNetService.delegate = self;
	[aNetService resolveWithTimeout:15];
	[services addObject:aNetService];
	NSLog(@"resolving %@ on %@ ..", aNetService.type, aNetService.name);
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
