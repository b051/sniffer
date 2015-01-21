//
//  SimpleMacAddress.h
//  sniffer
//
//  Created by Rex Sheng on 1/21/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimpleMacAddress : NSObject

+ (NSString *)ip2mac:(in_addr_t)addr;

@end
