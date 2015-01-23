//
//  DNSLookup.h
//  sniffer
//
//  Created by Rex Sheng on 1/22/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

// http://serverfault.com/questions/53576/windows-computer-name-ip-resolution-on-iphone
@interface DNSLookup : NSObject
- (NSArray *)hostnamesForAddress:(NSData *)address;
- (NSData *)convertAddress:(NSString *)ip;
@end
