//
//  DNSLookup.m
//  sniffer
//
//  Created by Rex Sheng on 1/22/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "DNSLookup.h"
#include <netdb.h>

@implementation DNSLookup
{
	Boolean done;
}

//https://eggerapps.at/blog/2014/hostname-lookups.html

void HostResolveCallback(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info) {
	DNSLookup *self = (__bridge DNSLookup *)info;
	NSLog(@"%@",@"!");
	self->done = true;
}

- (NSArray *)hostnamesForAddress:(NSString *)address
{
	// Get the host reference for the given address.
	struct addrinfo      hints;
	struct addrinfo      *result = NULL;
	memset(&hints, 0, sizeof(hints));
	hints.ai_flags    = AI_NUMERICHOST;
	hints.ai_family   = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = 0;
	int errorStatus = getaddrinfo([address cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
	if (errorStatus != 0) return nil;
	CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
	if (addressRef == nil) return nil;
	freeaddrinfo(result);
	CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
	if (hostRef == nil) return nil;
	CFRelease(addressRef);
	CFHostClientContext ctx = {.info = (__bridge void*)self};
	CFHostSetClient(hostRef, HostResolveCallback, &ctx);
	CFHostScheduleWithRunLoop(hostRef, CFRunLoopGetCurrent(), CFSTR("DNSResolverRunLoopMode"));
	BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
	if (!isSuccess) return nil;
	while (!done) {
		CFRunLoopRunInMode(CFSTR("DNSResolverRunLoopMode"), 0.05, true);
	}
	// Get the hostnames for the host reference.
	CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
	NSArray *hosts = [(__bridge NSArray *)hostnamesRef copy];
	return hosts;
}

@end
