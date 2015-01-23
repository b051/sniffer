//
//  SimpleMacAddress.m
//  sniffer
//
//  Created by Rex Sheng on 1/21/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "SimpleMacAddress.h"
#if !TARGET_IPHONE_SIMULATOR
#include <sys/sysctl.h>
#include <net/if_dl.h>
#include "route.h"
#include "if_ether.h"
#include <err.h>
#endif

@implementation SimpleMacAddress

+ (NSString *)ip2mac:(in_addr_t)addr
{
	NSString *ret = nil;
#if !TARGET_IPHONE_SIMULATOR
	int mib[6];
	
	mib[0] = CTL_NET;
	mib[1] = PF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_INET;
	mib[4] = NET_RT_FLAGS;
	mib[5] = RTF_LLINFO;
	
	char *buf;
	size_t needed;
	
	if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0)
		err(1, "route-sysctl-estimate");
	
	if ((buf = (char*)malloc(needed)) == NULL)
		err(1, "malloc");
	
	if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0)
		err(1, "retrieval of routing table");
	
	char *next;
	
	struct rt_msghdr *rtm;
	struct sockaddr_inarp *sin;
	struct sockaddr_dl *sdl;
	for (next = buf; next < buf + needed; next += rtm->rtm_msglen) {
		
		rtm = (struct rt_msghdr *)next;
		sin = (struct sockaddr_inarp *)(rtm + 1);
		sdl = (struct sockaddr_dl *)(sin + 1);
		if (addr != sin->sin_addr.s_addr || sdl->sdl_alen < 6)
			continue;
		
		u_char *cp = (u_char*)LLADDR(sdl);
		
		ret = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
			   cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
		
		break;
	}
	
	free(buf);
#endif
	return ret;
}

@end
