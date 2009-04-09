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
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:@"sample-rss-2"
																											 ofType:@"rss"]];
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

- (void)testSampleRSSOhNineTwo {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:@"sample-rss-092"
																											 ofType:@"rss"]];
	NSError *error = nil;
	FPFeed *feed = [FPParser parsedFeedWithData:data error:&error];
	STAssertNotNil(feed, @"FPParser returned error: %@", [error localizedDescription]);
	if (feed == nil) return;
	STAssertEqualObjects(feed.title, @"Dave Winer: Grateful Dead", nil);
	STAssertEquals([feed.items count], 22u, nil);
	FPItem *item = [feed.items objectAtIndex:18];
	STAssertEqualObjects(item.content, @"Truckin, like the doo-dah man, once told me gotta play your hand. Sometimes the cards ain't worth a dime, if you don't lay em down.", nil);
}

- (void)testSampleRSSOhNineOne {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:@"sample-rss-092"
																											 ofType:@"rss"]];
	NSError *error = nil;
	FPFeed *feed = [FPParser parsedFeedWithData:data error:&error];
	STAssertNotNil(feed, @"FPParser returned error: %@", [error localizedDescription]);
}

- (void)testExtensionElements {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:@"extensions"
																											 ofType:@"rss"]];
	NSError *error = nil;
	FPFeed *feed = [FPParser parsedFeedWithData:data error:&error];
	STAssertNotNil(feed, @"FPParser returned error: %@", [error localizedDescription]);
	if (feed == nil) return;
	STAssertEquals([feed.extensionElements count], 3u, nil);
	FPExtensionNode *node = [feed.extensionElements objectAtIndex:0];
	STAssertTrue(node.isElement, nil);
	STAssertEqualObjects(node.name, @"updatePeriod", nil);
	STAssertEqualObjects(node.namespaceURI, @"http://purl.org/rss/1.0/modules/syndication/", nil);
	STAssertEqualObjects(node.stringValue, @"hourly", nil);
	STAssertEquals([[feed extensionElementsWithXMLNamespace:@"http://purl.org/rss/1.0/modules/syndication/"] count], 2u, nil);
	FPItem *item = [feed.items objectAtIndex:0];
	STAssertEquals([item.extensionElements count], 2u, nil);
	STAssertEquals([[item extensionElementsWithXMLNamespace:@"uri:fake"] count], 1u, nil);
	FPExtensionNode *fake = [[item extensionElementsWithXMLNamespace:@"uri:fake"] objectAtIndex:0];
	NSLog(@"fake: %@", fake.children);
	STAssertEquals([fake.children count], 5u, @"node children: %@", fake.children);
	STAssertEqualObjects([[fake.children objectAtIndex:0] stringValue], @"\n            Text", nil);
	FPExtensionNode *child = [fake.children objectAtIndex:1];
	STAssertTrue(child.isElement, nil);
	STAssertEqualObjects(child.name, @"child", nil);
	STAssertEqualObjects(child.namespaceURI, @"uri:fake", nil);
	STAssertEqualObjects(child.stringValue, @"Child", nil);
	STAssertEqualObjects([[fake.children objectAtIndex:2] stringValue], @"\n            CDATA data\n            ", nil);
	child = [fake.children objectAtIndex:3];
	STAssertTrue(child.isElement, nil);
	STAssertEqualObjects(child.stringValue, @"Child 2", nil);
	STAssertEqualObjects([[fake.children objectAtIndex:4] stringValue], @"\n         ", nil);
}
@end
