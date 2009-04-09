//
//  FPItem.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPItem.h"
#import "NSDate_FeedParserExtensions.h"

@interface FPItem ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *link;
@property (nonatomic, copy, readwrite) NSString *guid;
@property (nonatomic, copy, readwrite) NSString *content;
@property (nonatomic, copy, readwrite) NSDate *pubDate;
@property (nonatomic, copy, readwrite) NSString *creator;
@end

@implementation FPItem
@synthesize title, link, guid, content, pubDate;
@synthesize creator;

+ (void)initialize {
	if (self == [FPItem class]) {
		[self registerHandler:@selector(setTitle:) forElement:@"title" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setLink:) forElement:@"link" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setGuid:) forElement:@"guid" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setContent:) forElement:@"description" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" namespaceURI:@"" type:FPXMLParserTextElementType];
		for (NSString *key in [NSArray arrayWithObjects:@"author", @"category", @"comments", @"enclosure", @"source", nil]) {
			[self registerHandler:NULL forElement:key namespaceURI:@"" type:FPXMLParserSkipElementType];
		}
		[self registerHandler:@selector(setCreator:) forElement:@"creator"
				 namespaceURI:kFPXMLParserDublinCoreNamespaceURI type:FPXMLParserTextElementType];
	}
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSDate *date = [NSDate dateWithRFC822:textValue];
	self.pubDate = date;
	if (date == nil) [self abortParsing:parser];
}

- (void)dealloc {
	[title release];
	[link release];
	[guid release];
	[content release];
	[pubDate release];
	[creator release];
	[super dealloc];
}
@end
