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
	if (error != NULL && error->domain != 0) {
		NSLog(@"CFStreamError domain = %ld",  error->domain);
	}
	self->done = true;
}

- (NSData *)convertAddress:(NSString *)ip
{
	// Get the host reference for the given address.
	struct addrinfo      hints;
	struct addrinfo      *result = NULL;
	memset(&hints, 0, sizeof(hints));
	hints.ai_flags    = AI_NUMERICHOST | AI_NUMERICSERV;
//	hints.ai_family   = PF_UNSPEC;
//	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = 0;
	int errorStatus = getaddrinfo([ip cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
	if (errorStatus != 0) return nil;
	CFDataRef addressRef = CFDataCreate(CFAllocatorGetDefault(), (UInt8 *)result->ai_addr, result->ai_addrlen);
	if (addressRef == nil) return nil;
	freeaddrinfo(result);

	NSData *data = [(__bridge NSData *)addressRef copy];
	CFRelease(addressRef);
	return data;
}

- (NSArray *)hostnamesForAddress:(NSData *)address
{
	Boolean success;
	CFStreamError streamError;
	CFHostRef hostRef = CFHostCreateWithAddress(CFAllocatorGetDefault(), (__bridge CFDataRef)address);
	if (hostRef == nil) return nil;
	CFHostClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
	CFHostSetClient(hostRef, HostResolveCallback, &context);
	CFHostScheduleWithRunLoop(hostRef, CFRunLoopGetCurrent(), CFSTR("DNSResolverRunLoopMode"));
	success = CFHostStartInfoResolution(hostRef, kCFHostNames, &streamError);
	if (!success) {
		return nil;
	}
	while (!done) {
		CFRunLoopRunInMode(CFSTR("DNSResolverRunLoopMode"), 0.05, true);
	}
	// Get the hostnames for the host reference.
	CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
	NSMutableArray *hostnames = [NSMutableArray array];
	for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
		[hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
	}
	CFHostUnscheduleFromRunLoop(hostRef, CFRunLoopGetCurrent(), CFSTR("DNSResolverRunLoopMode"));
	return hostnames;
}

@end
