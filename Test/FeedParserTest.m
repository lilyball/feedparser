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
	STAssertEquals([feed.items count], 4u, nil);
	FPItem *item = [feed.items objectAtIndex:2];
	STAssertEqualObjects(item.title, @"The Engine That Does More", nil);
	STAssertEqualObjects(item.link, @"http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp", nil);
	STAssertEqualObjects(item.content, @"Before man travels to Mars, NASA hopes to design new engines that will let \
us fly through the Solar System more quickly.  The proposed VASIMR engine would do that.", nil);
	STAssertEqualObjects(item.pubDate, [NSDate dateWithTimeIntervalSince1970:1054024652], nil);
	STAssertEqualObjects(item.guid, @"http://liftoff.msfc.nasa.gov/2003/05/27.html#item571", nil);
}
@end
