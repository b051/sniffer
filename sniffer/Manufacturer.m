//
//  Manufacturer.m
//  sniffer
//
//  Created by Rex Sheng on 1/23/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

#import "Manufacturer.h"
@implementation NSData (DDAdditions)

- (NSRange) rangeOfData_dd:(NSData *)dataToFind
{
	const void * bytes = [self bytes];
	NSUInteger length = [self length];
	
	const void * searchBytes = [dataToFind bytes];
	NSUInteger searchLength = [dataToFind length];
	NSUInteger searchIndex = 0;
	
	NSRange foundRange = {NSNotFound, searchLength};
	for (NSUInteger index = 0; index < length; index++) {
		if (((char *)bytes)[index] == ((char *)searchBytes)[searchIndex]) {
			//the current character matches
			if (foundRange.location == NSNotFound) {
				foundRange.location = index;
			}
			searchIndex++;
			if (searchIndex >= searchLength) {
				return foundRange;
			}
		} else {
			searchIndex = 0;
			foundRange.location = NSNotFound;
		}
	}
	if (searchIndex < searchLength) {
		foundRange.location = NSNotFound;
	}
	return foundRange;
}

@end

@implementation Manufacturer
{
	unsigned long long totalFileLength;
}

+ (NSString *)mac2manufacturer:(NSString *)mac
{
	mac = [[mac stringByReplacingOccurrencesOfString:@":" withString:@""] substringToIndex:6];
	NSString *oui = [[NSBundle mainBundle] pathForResource:@"oui" ofType:@"txt"];
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:oui];
	[handle seekToEndOfFile];
	unsigned long long totalFileLength = [handle offsetInFile];
	unsigned long long currentOffset = 0;
	NSUInteger chunkSize = 10;
	NSData *newLineData = [@"\n\n\n" dataUsingEncoding:NSUTF8StringEncoding];
	NSString *returnLine = nil;
	while (currentOffset < totalFileLength) {
		[handle seekToFileOffset:currentOffset];
		NSMutableData * currentData = [[NSMutableData alloc] init];
		BOOL shouldReadMore = YES;
		@autoreleasepool {
			while (shouldReadMore) {
				if (currentOffset >= totalFileLength) { break; }
				NSData *chunk = [handle readDataOfLength:chunkSize];
				NSRange newLineRange = [chunk rangeOfData_dd:newLineData];
				if (newLineRange.location != NSNotFound) {
					
					//include the length so we can include the delimiter in the string
					chunk = [chunk subdataWithRange:NSMakeRange(0, newLineRange.location + newLineRange.length)];
					shouldReadMore = NO;
				}
				[currentData appendData:chunk];
				currentOffset += [chunk length];
			}
			NSString *line = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
			if ([line containsString:mac]) {
				returnLine = line;
				break;
			}
		}
	}
	NSString *manufacturer = [returnLine substringFromIndex:6];
	manufacturer = [manufacturer stringByReplacingOccurrencesOfString:@"[\t\n]+" withString:@"\n" options:NSRegularExpressionSearch range:NSMakeRange(0, manufacturer.length)];
	return manufacturer;
}

	@end
