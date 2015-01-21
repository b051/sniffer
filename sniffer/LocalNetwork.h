//
//  LocalNetwork.h
//  sniffer
//
//  Created by Rex Sheng on 1/20/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LocalNetworkDelegate <NSObject>

- (void)localNetworkDidFindDevice:(NSString *)ip;
- (void)localNetworkDidFindDevice:(NSString *)ip port:(int16_t)port;
- (void)localNetworkDidFinish;
- (void)localNetworkDidFinishPortScan;

@end

@interface LocalNetwork : NSObject

@property (nonatomic, weak) id<LocalNetworkDelegate> delegate;
@property (nonatomic, strong, readonly) NSArray *localDevices;
- (void)scanDevices;
- (void)portsScan:(NSString *)ip;

@end
