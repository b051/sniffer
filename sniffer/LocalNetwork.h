//
//  LocalNetwork.h
//  sniffer
//
//  Created by Rex Sheng on 1/20/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LocalDevice;
@protocol LocalNetworkDelegate <NSObject>

- (void)localNetworkDidFindDevice:(NSString *)ip;
- (void)localNetworkDidFinish;

@end

@interface LocalNetwork : NSObject

@property (nonatomic, weak) id<LocalNetworkDelegate> delegate;
@property (nonatomic, strong, readonly) NSArray *localDevices;
- (void)scanDevices;

+ (NSString *)readableIPv4Address:(in_addr_t)address;

@end
