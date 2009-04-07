//
//  FPFeed.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPFeed.h"
#import "FPItem.h"
#import "FPParser.h"
#import "NSDate_FeedParserExtensions.h"

@interface FPFeed ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *link;
@property (nonatomic, copy, readwrite) NSString *feedDescription;
@property (nonatomic, copy, readwrite) NSDate *pubDate;
@end

@implementation FPFeed
@synthesize title, link, feedDescription, pubDate, items;

+ (void)initialize {
	if (self == [FPFeed class]) {
		[self registerHandler:@selector(setTitle:) forElement:@"title" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setLink:) forElement:@"link" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setFeedDescription:) forElement:@"description" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" namespaceURI:@"" type:FPXMLParserTextElementType];
		for (NSString *key in [NSArray arrayWithObjects:
							   @"language", @"copyright", @"managingEditor", @"webMaster", @"lastBuildDate", @"category",
							   @"generator", @"docs", @"cloud", @"ttl", @"image", @"rating", @"textInput", @"skipHours", @"skipDays", nil]) {
			[self registerHandler:NULL forElement:key namespaceURI:@"" type:FPXMLParserSkipElementType];
		}
		[self registerHandler:@selector(rss_item:parser:) forElement:@"item" namespaceURI:@"" type:FPXMLParserStreamElementType];
		
		// atom elements
		[self registerHandler:@selector(atom_link:attributes:parser:) forElement:@"link"
				 namespaceURI:kFPXMLParserAtomNamespaceURI type:FPXMLParserTextElementType];
	}
}

- (id)initWithParser:(NSXMLParser *)parser baseNamespaceURI:namespaceURI {
	if (self = [super initWithParser:parser baseNamespaceURI:namespaceURI]) {
		items = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSDate *date = [NSDate dateWithRFC822:textValue];
	self.pubDate = date;
	if (date == nil) [self abortParsing:parser];
}

- (void)rss_item:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FPItem *item = [[FPItem alloc] initWithParser:parser baseNamespaceURI:baseNamespaceURI];
	[items addObject:item];
	[item release];
}

- (void)atom_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *rel = [attributes objectForKey:@"rel"];
	if (rel == nil || [rel isEqualToString:@"alternate"]) {
		self.link = [attributes objectForKey:@"href"];
	}
}

- (void)dealloc {
	[title release];
	[link release];
	[feedDescription release];
	[pubDate release];
	[items release];
	[super dealloc];
}
@end
