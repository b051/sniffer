//
//  BonjourBrowser.h
//  sniffer
//
//  Created by Rex Sheng on 1/23/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BonjourBrowserDelegate <NSObject>

- (void)bonjourBrowserDidFindService:(NSNetService *)service;
- (void)bonjourBrowserDidFinish;

@end

@interface BonjourBrowser : NSObject

- (void)start;
@property (nonatomic, weak) id<BonjourBrowserDelegate> delegate;

@end
