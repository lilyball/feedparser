//
//  FeedParserTest.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "FeedParserTest.h"
#import "FeedParser.h"

@implementation FeedParserTest
// to produce an epoch from a date, use `date -j -f '%a, %d %b %Y %H:%M:%S %Z' 'Tue, 10 Jun 2003 04:00:00 GMT' +'%s'`

- (FPFeed *)feedFromFixture:(NSString *)fixture {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:fixture ofType:nil]];
	NSError *error = nil;
	FPFeed *feed = [FPParser parsedFeedWithData:data error:&error];
	STAssertNotNil(feed, @"FPParser returned error: %@", [error localizedDescription]);
	return feed;
}

- (void)testSampleRSSTwo {
	FPFeed *feed = [self feedFromFixture:@"sample-rss-2.rss"];
	if (feed == nil) return;
	STAssertEqualObjects(feed.title, @"Liftoff News", nil);
	STAssertEqualObjects(feed.link.href, @"http://liftoff.msfc.nasa.gov/", nil);
	STAssertEqualObjects(feed.feedDescription, @"Liftoff to Space Exploration.", nil);
	STAssertEqualObjects(feed.pubDate, [NSDate dateWithTimeIntervalSince1970:1055217600], nil);
	STAssertEquals([feed.items count], 4u, nil);
	FPItem *item = [feed.items objectAtIndex:2];
	STAssertEqualObjects(item.title, @"The Engine That Does More", nil);
	STAssertEqualObjects(item.link.href, @"http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp", nil);
	STAssertEqualObjects(item.content, @"Before man travels to Mars, NASA hopes to design new engines that will let \
us fly through the Solar System more quickly.  The proposed VASIMR engine would do that.", nil);
	STAssertEqualObjects(item.pubDate, [NSDate dateWithTimeIntervalSince1970:1054024652], nil);
	STAssertEqualObjects(item.guid, @"http://liftoff.msfc.nasa.gov/2003/05/27.html#item571", nil);
}

- (void)testSampleRSSOhNineTwo {
	FPFeed *feed = [self feedFromFixture:@"sample-rss-092.rss"];
	if (feed == nil) return;
	STAssertEqualObjects(feed.title, @"Dave Winer: Grateful Dead", nil);
	STAssertEquals([feed.items count], 22u, nil);
	FPItem *item = [feed.items objectAtIndex:18];
	STAssertEqualObjects(item.content, @"Truckin, like the doo-dah man, once told me gotta play your hand. Sometimes the cards ain't worth a dime, if you don't lay em down.", nil);
}

- (void)testSampleRSSOhNineOne {
	// for now, just make sure it loads
	[self feedFromFixture:@"sample-rss-091.rss"];
}

- (void)testExtensionElements {
	FPFeed *feed = [self feedFromFixture:@"extensions.rss"];
	if (feed == nil) return;
	STAssertEquals([feed.extensionElements count], 3u, nil);
	FPExtensionNode *node = [feed.extensionElements objectAtIndex:0];
	STAssertTrue(node.isElement, nil);
	STAssertEqualObjects(node.name, @"updatePeriod", nil);
	STAssertEqualObjects(node.namespaceURI, @"http://purl.org/rss/1.0/modules/syndication/", nil);
	STAssertEqualObjects(node.stringValue, @"hourly", nil);
	STAssertEquals([[feed extensionElementsWithXMLNamespace:@"http://purl.org/rss/1.0/modules/syndication/"] count], 2u, nil);
	FPItem *item = [feed.items objectAtIndex:0];
	STAssertEquals([item.extensionElements count], 3u, nil);
	STAssertEquals([[item extensionElementsWithXMLNamespace:@"uri:fake"] count], 2u, nil);
	FPExtensionNode *fake = [[item extensionElementsWithXMLNamespace:@"uri:fake"] objectAtIndex:0];
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
	STAssertEqualObjects([[[item extensionElementsWithXMLNamespace:@"uri:fake"] objectAtIndex:1] name], @"empty", nil);
	STAssertEquals([[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"tree"] count], 1u, nil);
	STAssertEquals([[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"empty"] count], 1u, nil);
	STAssertEquals([[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"bogus"] count], 0u, nil);
	STAssertEqualObjects([[[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"empty"] objectAtIndex:0] name], @"empty", nil);
}

- (void)testLinks {
	FPFeed *feed = [self feedFromFixture:@"rss-with-atom.rss"];
	if (feed == nil) return;
	STAssertEqualObjects(feed.link, [FPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/" rel:@"alternate" type:nil title:nil], nil);
	STAssertEquals([feed.links count], 2u, nil);
	STAssertEqualObjects([feed.links objectAtIndex:0], feed.link, nil);
	STAssertEqualObjects([feed.links objectAtIndex:1], [FPLink linkWithHref:@"file:///path/to/rss-with-atom.rss" rel:@"self"
																	   type:@"application/rss+xml" title:nil], nil);
	STAssertEquals([feed.items count], 4u, nil);
	// item 0
	FPFeed *item = [feed.items objectAtIndex:0];
	STAssertEqualObjects(item.link, [FPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp" rel:@"alternate"
													type:nil title:nil], nil);
	STAssertEqualObjects(item.links, [NSArray arrayWithObject:item.link], nil);
	// item 1
	item = [feed.items objectAtIndex:1];
	STAssertEqualObjects(item.link, [FPLink linkWithHref:@"http://fake/" rel:@"alternate" type:nil title:nil], nil);
	STAssertEqualObjects(item.links, [NSArray arrayWithObject:item.link], nil);
	// item 2
	item = [feed.items objectAtIndex:2];
	STAssertEqualObjects(item.link, [FPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp" rel:@"alternate"
													type:nil title:nil], nil);
	NSArray *links = [NSArray arrayWithObjects:item.link, [FPLink linkWithHref:@"http://fake/" rel:@"alternate" type:nil title:nil], nil];
	STAssertEqualObjects(item.links, links, nil);
	// item 3
	item = [feed.items objectAtIndex:3];
	STAssertEqualObjects(item.link, [FPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/news/2003/news-laundry.asp" rel:@"alternate"
													type:nil title:nil], nil);
	links = [NSArray arrayWithObjects:[FPLink linkWithHref:@"http://fake/" rel:@"random" type:@"text/plain" title:@"A fake link"], item.link, nil];
	STAssertEqualObjects(item.links, links, nil);
}
@end
