//
//  FPFeed.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPFeed.h"
#import "FPItem.h"
#import "FPLink.h"
#import "FPParser.h"
#import "NSDate_FeedParserExtensions.h"

@interface FPFeed ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *feedDescription;
@property (nonatomic, copy, readwrite) NSDate *pubDate;
- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_item:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
@end

@implementation FPFeed
@synthesize title, link, links, feedDescription, pubDate, items;

+ (void)initialize {
	if (self == [FPFeed class]) {
		[self registerHandler:@selector(setTitle:) forElement:@"title" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(rss_link:attributes:parser:) forElement:@"link" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setFeedDescription:) forElement:@"description" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" namespaceURI:@"" type:FPXMLParserTextElementType];
		for (NSString *key in [NSArray arrayWithObjects:
							   @"language", @"copyright", @"managingEditor", @"webMaster", @"lastBuildDate", @"category",
							   @"generator", @"docs", @"cloud", @"ttl", @"image", @"rating", @"textInput", @"skipHours", @"skipDays", nil]) {
			[self registerHandler:NULL forElement:key namespaceURI:@"" type:FPXMLParserSkipElementType];
		}
		[self registerHandler:@selector(rss_item:parser:) forElement:@"item" namespaceURI:@"" type:FPXMLParserStreamElementType];
		
		// atom elements
		[self registerHandler:@selector(atom_link:parser:) forElement:@"link"
				 namespaceURI:kFPXMLParserAtomNamespaceURI type:FPXMLParserSkipElementType];
	}
}

- (id)initWithBaseNamespaceURI:namespaceURI {
	if (self = [super initWithBaseNamespaceURI:namespaceURI]) {
		items = [[NSMutableArray alloc] init];
		links = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSDate *date = [NSDate dateWithRFC822:textValue];
	self.pubDate = date;
	if (date == nil) [self abortParsing:parser];
}

- (void)rss_item:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FPItem *item = [[FPItem alloc] initWithBaseNamespaceURI:baseNamespaceURI];
	[item acceptParsing:parser];
	[items addObject:item];
	[item release];
}

- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FPLink *aLink = [[FPLink alloc] initWithHref:textValue rel:@"alternate" type:nil title:nil];
	if (link == nil) {
		link = [aLink retain];
	}
	[links addObject:aLink];
	[aLink release];
}

- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *href = [attributes objectForKey:@"href"];
	if (href == nil) return; // sanity check
	FPLink *aLink = [[FPLink alloc] initWithHref:href rel:[attributes objectForKey:@"rel"] type:[attributes objectForKey:@"type"]
										   title:[attributes objectForKey:@"title"]];
	if (link == nil && [aLink.rel isEqualToString:@"alternate"]) {
		link = [aLink retain];
	}
	[links addObject:aLink];
	[aLink release];
}

- (void)dealloc {
	[title release];
	[link release];
	[links release];
	[feedDescription release];
	[pubDate release];
	[items release];
	[super dealloc];
}
@end
