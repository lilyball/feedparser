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
- (NSDate *)dateFromRFC822String:(NSString *)rfc822 {
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss ZZZ"];
	return [formatter dateFromString:rfc822];
}

- (void)testSampleRSSTwo {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:@"sample-rss-2" ofType:@"rss"]];
	NSError *error = nil;
	FPFeed *feed = [FPParser parsedFeedWithData:data error:&error];
	STAssertNotNil(feed, @"FPParser returned error: %@", [error localizedDescription]);
	if (feed == nil) return;
	STAssertEqualObjects(feed.title, @"Liftoff News", nil);
	STAssertEqualObjects(feed.link, @"http://liftoff.msfc.nasa.gov/", nil);
	STAssertEqualObjects(feed.feedDescription, @"Liftoff to Space Exploration.", nil);
	STAssertEqualObjects(feed.pubDate, [self dateFromRFC822String:@"Tue, 10 Jun 2003 04:00:00 GMT"], nil);
}
@end
