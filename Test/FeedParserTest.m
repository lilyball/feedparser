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

@import XCTest;

#import "FeedParser.h"

@interface FeedParserTest : XCTestCase
@end

@implementation FeedParserTest
// to produce an epoch from a date, use `date -j -f '%a, %d %b %Y %H:%M:%S %Z' 'Tue, 10 Jun 2003 04:00:00 GMT' +'%s'`

- (FDPFeed *)feedFromFixture:(NSString *)fixture {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[FeedParserTest class]] pathForResource:fixture ofType:nil]];
	NSError *error = nil;
	FDPFeed *feed = [FDPParser parsedFeedWithData:data error:&error];
	XCTAssertNotNil(feed, @"FDPParser returned error: %@", [error localizedDescription]);
	return feed;
}

- (void)testSampleRSSTwo {
	FDPFeed *feed = [self feedFromFixture:@"sample-rss-2.rss"];
	NSAssert(feed != nil, @"sample-rss-2.rss feed was nil");
	XCTAssertEqualObjects(feed.title, @"Liftoff News");
	XCTAssertEqualObjects(feed.link.href, @"http://liftoff.msfc.nasa.gov/");
	XCTAssertEqualObjects(feed.feedDescription, @"Liftoff to Space Exploration.");
	XCTAssertEqualObjects(feed.pubDate, [NSDate dateWithTimeIntervalSince1970:1055217600]);
	XCTAssertEqual([feed.items count], (NSUInteger)4);
	FDPItem *item = [feed.items objectAtIndex:2];
	XCTAssertEqualObjects(item.title, @"The Engine That Does More");
	XCTAssertEqualObjects(item.link.href, @"http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp");
	XCTAssertEqualObjects(item.description, @"Before man travels to Mars, NASA hopes to design new engines that will let \
us fly through the Solar System more quickly.  The proposed VASIMR engine would do that.");
	XCTAssertEqualObjects(item.pubDate, [NSDate dateWithTimeIntervalSince1970:1054024652]);
	XCTAssertEqualObjects(item.guid, @"http://liftoff.msfc.nasa.gov/2003/05/27.html#item571");
	XCTAssertEqualObjects(item.author, @"fake@nasa.gov");
}

- (void)testSampleRSSOhNineTwo {
	FDPFeed *feed = [self feedFromFixture:@"sample-rss-092.rss"];
	NSAssert(feed != nil, @"sample-rss-092.rss feed was nil");
	XCTAssertEqualObjects(feed.title, @"Dave Winer: Grateful Dead");
	XCTAssertEqual([feed.items count], (NSUInteger)22);
	FDPItem *item = [feed.items objectAtIndex:18];
	XCTAssertEqualObjects(item.description, @"Truckin, like the doo-dah man, once told me gotta play your hand. Sometimes the cards ain't worth a dime, if you don't lay em down.");
}

- (void)testSampleRSSOhNineOne {
	// for now, just make sure it loads
	[self feedFromFixture:@"sample-rss-091.rss"];
}

- (void)testExtensionElements {
	FDPFeed *feed = [self feedFromFixture:@"extensions.rss"];
	NSAssert(feed != nil, @"extensions.rss feed was nil");
	XCTAssertEqual([feed.extensionElements count], (NSUInteger)3);
	FDPExtensionNode *node = [feed.extensionElements objectAtIndex:0];
	XCTAssertTrue(node.isElement);
	XCTAssertEqualObjects(node.name, @"updatePeriod");
	XCTAssertEqualObjects(node.namespaceURI, @"http://purl.org/rss/1.0/modules/syndication/");
	XCTAssertEqualObjects(node.stringValue, @"hourly");
	XCTAssertEqual([[feed extensionElementsWithXMLNamespace:@"http://purl.org/rss/1.0/modules/syndication/"] count], (NSUInteger)2);
	FDPItem *item = [feed.items objectAtIndex:0];
	XCTAssertEqual([item.extensionElements count], (NSUInteger)3);
	// fake
	XCTAssertEqual([[item extensionElementsWithXMLNamespace:@"uri:fake"] count], (NSUInteger)2);
	FDPExtensionNode *fake = [[item extensionElementsWithXMLNamespace:@"uri:fake"] objectAtIndex:0];
	XCTAssertEqual([fake.children count], (NSUInteger)5, @"node children: %@", fake.children);
	XCTAssertEqualObjects([[fake.children objectAtIndex:0] stringValue], @"\n            Text");
	FDPExtensionNode *child = [fake.children objectAtIndex:1];
	XCTAssertTrue(child.isElement);
	XCTAssertEqualObjects(child.name, @"child");
	XCTAssertEqualObjects(child.namespaceURI, @"uri:fake");
	XCTAssertEqualObjects(child.stringValue, @"Child");
	XCTAssertEqualObjects([[fake.children objectAtIndex:2] stringValue], @"\n            CDATA data\n            ");
	child = [fake.children objectAtIndex:3];
	XCTAssertTrue(child.isElement);
	XCTAssertEqualObjects(child.stringValue, @"Child 2");
	XCTAssertEqualObjects([[fake.children objectAtIndex:4] stringValue], @"\n         ");
	XCTAssertEqualObjects([[[item extensionElementsWithXMLNamespace:@"uri:fake"] objectAtIndex:1] name], @"empty");
	XCTAssertEqual([[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"tree"] count], (NSUInteger)1);
	XCTAssertEqual([[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"empty"] count], (NSUInteger)1);
	XCTAssertEqual([[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"bogus"] count], (NSUInteger)0);
	XCTAssertEqualObjects([[[item extensionElementsWithXMLNamespace:@"uri:fake" elementName:@"empty"] objectAtIndex:0] name], @"empty");
	// content
	XCTAssertEqual([[item extensionElementsWithXMLNamespace:kFDPXMLParserContentNamespaceURI] count], (NSUInteger)1);
	FDPExtensionNode *encoded = [[item extensionElementsWithXMLNamespace:kFDPXMLParserContentNamespaceURI] objectAtIndex:0];
	XCTAssertEqualObjects(encoded.name, @"encoded");
	XCTAssertEqualObjects(encoded.qualifiedName, @"content:encoded");
	XCTAssertEqualObjects(encoded.namespaceURI, kFDPXMLParserContentNamespaceURI);
	XCTAssertTrue(encoded.isElement);
	XCTAssertEqual([encoded.children count], (NSUInteger)1);
	XCTAssertTrue([[encoded.children objectAtIndex:0] isTextNode]);
	XCTAssertEqualObjects(encoded.stringValue,
						 @"<p>How do Americans get ready to work with Russians aboard the International Space Station? " \
						 @"They take a crash course in culture, language and protocol at Russia's " \
						 @"<a href=\"http://howe.iki.rssi.ru/GCTC/gctc_e.htm\">Star City</a>.</p>");
	XCTAssertEqualObjects(item.content, encoded.stringValue);
	XCTAssertEqualObjects(item.description,
						 @"How do Americans get ready to work with Russians aboard the International Space Station? " \
						 @"They take a crash course in culture, language and protocol at Russia's " \
						 @"<a href=\"http://howe.iki.rssi.ru/GCTC/gctc_e.htm\">Star City</a>.");
	
	// test fake textual extension element, in this case <dc:creator></dc:creator>
	item = [feed.items objectAtIndex:3];
	XCTAssertNotNil(item.creator);
	XCTAssertEqualObjects(item.creator, @"");
	FDPExtensionNode *creator = [[item extensionElementsWithXMLNamespace:kFDPXMLParserDublinCoreNamespaceURI] objectAtIndex:0];
	XCTAssertEqualObjects(creator.name, @"creator");
	XCTAssertEqual([creator.children count], (NSUInteger)0);
	XCTAssertEqualObjects(creator.stringValue, @"");
}

- (void)testSupportedExtensions {
	FDPFeed *feed = [self feedFromFixture:@"extensions.rss"];
	NSAssert(feed != nil, @"extensions.rss feed was nil");
	FDPItem *item = [feed.items objectAtIndex:0];
	XCTAssertFalse(item.description == item.content);
	XCTAssertEqualObjects(item.description,
						 @"How do Americans get ready to work with Russians aboard the International Space Station? " \
						 @"They take a crash course in culture, language and protocol at Russia's " \
						 @"<a href=\"http://howe.iki.rssi.ru/GCTC/gctc_e.htm\">Star City</a>.");
	XCTAssertEqualObjects(item.content,
						 @"<p>How do Americans get ready to work with Russians aboard the International Space Station? " \
						 @"They take a crash course in culture, language and protocol at Russia's " \
						 @"<a href=\"http://howe.iki.rssi.ru/GCTC/gctc_e.htm\">Star City</a>.</p>");
	XCTAssertNil(item.creator);
	item = [feed.items objectAtIndex:2];
	XCTAssertTrue(item.description == item.content);
	XCTAssertEqualObjects(item.creator, @"Joe Smith");
	XCTAssertNil(item.author);
}

- (void)testLinks {
	FDPFeed *feed = [self feedFromFixture:@"rss-with-atom.rss"];
	NSAssert(feed != nil, @"rss-with-atom.rss feed was nil");
	XCTAssertEqualObjects(feed.link, [FDPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/" rel:@"alternate" type:nil title:nil]);
	XCTAssertEqual([feed.links count], (NSUInteger)2);
	XCTAssertEqualObjects([feed.links objectAtIndex:0], feed.link);
	XCTAssertEqualObjects([feed.links objectAtIndex:1], [FDPLink linkWithHref:@"file:///path/to/rss-with-atom.rss" rel:@"self"
																	   type:@"application/rss+xml" title:nil]);
	XCTAssertEqual([feed.items count], (NSUInteger)4);
	// item 0
	FDPItem *item = [feed.items objectAtIndex:0];
	XCTAssertEqualObjects(item.link, [FDPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp" rel:@"alternate"
													type:nil title:nil]);
	XCTAssertEqualObjects(item.links, [NSArray arrayWithObject:item.link]);
	// item 1
	item = [feed.items objectAtIndex:1];
	XCTAssertEqualObjects(item.link, [FDPLink linkWithHref:@"http://fake/" rel:@"alternate" type:nil title:nil]);
	XCTAssertEqualObjects(item.links, [NSArray arrayWithObject:item.link]);
	// item 2
	item = [feed.items objectAtIndex:2];
	XCTAssertEqualObjects(item.link, [FDPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp" rel:@"alternate"
													type:nil title:nil]);
	NSArray *links = [NSArray arrayWithObjects:item.link, [FDPLink linkWithHref:@"http://fake/" rel:@"alternate" type:nil title:nil], nil];
	XCTAssertEqualObjects(item.links, links);
	// item 3
	item = [feed.items objectAtIndex:3];
	XCTAssertEqualObjects(item.link, [FDPLink linkWithHref:@"http://liftoff.msfc.nasa.gov/news/2003/news-laundry.asp" rel:@"alternate"
													type:nil title:nil]);
	links = [NSArray arrayWithObjects:[FDPLink linkWithHref:@"http://fake/" rel:@"random" type:@"text/plain" title:@"A fake link"], item.link, nil];
	XCTAssertEqualObjects(item.links, links);
}

- (void)testEnclosures {
	FDPFeed *feed = [self feedFromFixture:@"sample-rss-092.rss"];
	if (feed == nil) return;
	FDPItem *item = [feed.items objectAtIndex:0];
	XCTAssertEqual([item.enclosures count], (NSUInteger)1);
	XCTAssertEqualObjects([item.enclosures objectAtIndex:0], [FDPEnclosure enclosureWithURL:@"http://www.scripting.com/mp3s/weatherReportDicksPicsVol7.mp3" length:6182912 type:@"audio/mpeg"]);
}

- (void)testCategories {
	FDPFeed *feed = [self feedFromFixture:@"sample-rss-092.rss"];
	NSAssert(feed != nil, @"sample-rss-092.rss feed was nil");
    FDPItem *item = [feed.items objectAtIndex:14];
    XCTAssertEqual([item.categories count], (NSUInteger)1);
    XCTAssertEqualObjects([item.categories objectAtIndex:0], [FDPCategory categoryWithDomain:nil value:@"Grateful Dead"]);
    item = [feed.items objectAtIndex:15];
    XCTAssertEqual([item.categories count], (NSUInteger)2);
    XCTAssertEqualObjects([item.categories objectAtIndex:0], [FDPCategory categoryWithDomain:@"http://www.tildesoft.com/foo" value:@"Bar"]);
    XCTAssertEqualObjects([item.categories objectAtIndex:1], [FDPCategory categoryWithDomain:nil value:@"Bar"]);
    XCTAssertFalse([[item.categories objectAtIndex:0] isEqual:[item.categories objectAtIndex:1]]);
}

- (void)testGoogleNews {
	// test a snapshot of http://news.google.com/news?output=rss taken on 4/27/2010
	// This was reported in issue #8 as causing a problem
	FDPFeed *feed = [self feedFromFixture:@"google-news.rss"];
	if (feed == nil) return;
	XCTAssertEqualObjects(feed.title, @"Top Stories - Google News");
	XCTAssertEqualObjects(feed.link.href, @"http://news.google.com?pz=1&ned=us&hl=en");
	FDPItem *item = [feed.items objectAtIndex:0];
	XCTAssertEqualObjects(item.title, @"Goldman's Blankfein hit hard on CDO conflicts - MarketWatch");
}

- (void)testArchiving {
	// test all fixtures to ensure the unarchived object is equal to the archived one
	NSArray *fixtures = [NSArray arrayWithObjects:@"sample-rss-091.rss", @"sample-rss-092.rss",
						 @"sample-rss-2.rss", @"extensions.rss", @"rss-with-atom.rss", @"google-news.rss", nil];
	for (NSString *fixture in fixtures) {
		FDPFeed *feed = [self feedFromFixture:fixture];
		if (feed == nil) continue;
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:feed];
		XCTAssertNotNil(data);
		FDPFeed *newFeed = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		XCTAssertNotNil(newFeed);
		XCTAssertEqualObjects(feed, newFeed);
	}
}
@end
