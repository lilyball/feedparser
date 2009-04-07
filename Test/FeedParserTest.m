//
//  FeedParserTest.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FeedParserTest.h"
#import "FeedParser.h"

@implementation FeedParserTest
// to produce an epoch from a date, use `date -j -f '%a, %d %b %Y %H:%M:%S %Z' 'Tue, 10 Jun 2003 04:00:00 GMT' +'%s'`

- (void)testSampleRSSTwo {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:@"sample-rss-2" ofType:@"rss"]];
	NSError *error = nil;
	FPFeed *feed = [FPParser parsedFeedWithData:data error:&error];
	STAssertNotNil(feed, @"FPParser returned error: %@", [error localizedDescription]);
	if (feed == nil) return;
	STAssertEqualObjects(feed.title, @"Liftoff News", nil);
	STAssertEqualObjects(feed.link, @"http://liftoff.msfc.nasa.gov/", nil);
	STAssertEqualObjects(feed.feedDescription, @"Liftoff to Space Exploration.", nil);
	STAssertEqualObjects(feed.pubDate, [NSDate dateWithTimeIntervalSince1970:1055217600], nil);
}
@end
