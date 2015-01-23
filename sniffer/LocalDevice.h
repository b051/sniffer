//
//  LocalDevice.h
//  sniffer
//
//  Created by Rex Sheng on 1/23/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LocalDevice;

@protocol LocalDeviceDelegate <NSObject>

- (void)deviceDidFinishPortScan:(LocalDevice *)device;

@end

@interface LocalDevice : NSObject

@property (nonatomic) in_addr_t local_addr;
@property (nonatomic, strong) NSString *ipv4;
@property (nonatomic, strong) NSString *ipv6;
@property (nonatomic, strong) NSString *macAddress;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *hostName;
@property (nonatomic, strong) NSData *addressv4;
@property (nonatomic, strong) NSData *addressv6;
@property (nonatomic, strong) NSString *manufacturer;
@property (nonatomic, strong) NSMutableDictionary *ports;
@property (nonatomic, weak) id<LocalDeviceDelegate> delegate;

- (void)startPortsScan;
- (void)addService:(NSString *)type port:(NSInteger)port;

@end
