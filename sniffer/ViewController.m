//
//  ViewController.m
//  sniffer
//
//  Created by Rex Sheng on 1/20/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "ViewController.h"
#import "LocalNetwork.h"
#import "Manufacturer.h"

@interface ViewController () <LocalNetworkDelegate, NSNetServiceDelegate, UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController
{
	LocalNetwork *network;
	UITableView *tableView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];	
	tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:tableView];
	[tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 200;
	network = [LocalNetwork new];
	network.delegate = self;
	[network scanDevices];
}

#pragma mark - LocalNetworkDelegate
- (void)localNetworkDidFinish
{
	for (id device in network.localDevices) {
		NSLog(@"%@", device);
	}
	[tableView reloadData];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		for (id device in network.localDevices) {
			NSLog(@"%@", device);
		}
		[tableView reloadData];
	});
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	cell.textLabel.text = [network.localDevices[indexPath.row] description];
	cell.textLabel.numberOfLines = 0;
	return cell;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return network.localDevices.count;
}

@end
