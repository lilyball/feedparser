//
//  FDPFeed.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
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

#import "FDPFeed.h"
#import "FDPItem.h"
#import "FDPLink.h"
#import "FDPParser.h"
#import "NSDate_FeedParserExtensions.h"

@interface FDPFeed ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *feedDescription;
@property (nonatomic, copy, readwrite) NSDate *pubDate;
- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_item:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
@end

@implementation FDPFeed
@synthesize title, link, links, feedDescription, pubDate, items;

+ (void)initialize {
	if (self == [FDPFeed class]) {
		[self registerRSSHandler:@selector(setTitle:) forElement:@"title" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_link:attributes:parser:) forElement:@"link" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setFeedDescription:) forElement:@"description" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" type:FDPXMLParserTextElementType];
		for (NSString *key in [NSArray arrayWithObjects:
							   @"language", @"copyright", @"managingEditor", @"webMaster", @"lastBuildDate", @"category",
							   @"generator", @"docs", @"cloud", @"ttl", @"image", @"rating", @"textInput", @"skipHours", @"skipDays", nil]) {
			[self registerRSSHandler:NULL forElement:key type:FDPXMLParserSkipElementType];
		}
		[self registerRSSHandler:@selector(rss_item:parser:) forElement:@"item" type:FDPXMLParserStreamElementType];
		
		// atom elements
		[self registerAtomHandler:@selector(atom_link:parser:) forElement:@"link" type:FDPXMLParserSkipElementType];
	}
}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI {
	if (self = [super initWithBaseNamespaceURI:namespaceURI]) {
		items = [[NSMutableArray alloc] init];
		links = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSDate *date = [NSDate fdp_dateWithRFC822:textValue];
	self.pubDate = date;
	if (date == nil) [self abortParsing:parser withFormat:@"could not parse pubDate '%@'", textValue];
}

- (void)rss_item:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FDPItem *item = [[FDPItem alloc] initWithBaseNamespaceURI:baseNamespaceURI];
	[item acceptParsing:parser];
	[items addObject:item];
	[item release];
}

- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FDPLink *aLink = [[FDPLink alloc] initWithHref:textValue rel:@"alternate" type:nil title:nil];
	if (link == nil) {
		link = [aLink retain];
	}
	[links addObject:aLink];
	[aLink release];
}

- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *href = [attributes objectForKey:@"href"];
	if (href == nil) return; // sanity check
	FDPLink *aLink = [[FDPLink alloc] initWithHref:href rel:[attributes objectForKey:@"rel"] type:[attributes objectForKey:@"type"]
										   title:[attributes objectForKey:@"title"]];
	if (link == nil && [aLink.rel isEqualToString:@"alternate"]) {
		link = [aLink retain];
	}
	[links addObject:aLink];
	[aLink release];
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FDPFeed class]]) return NO;
	FDPFeed *other = (FDPFeed *)anObject;
	return ((title           == other->title           || [title           isEqualToString:other->title])           &&
			(link            == other->link            || [link            isEqual:other->link])                    &&
			(links           == other->links           || [links           isEqualToArray:other->links])            &&
			(feedDescription == other->feedDescription || [feedDescription isEqualToString:other->feedDescription]) &&
			(pubDate         == other->pubDate         || [pubDate         isEqual:other->pubDate])                 &&
			(items           == other->items           || [items           isEqualToArray:other->items]));
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

#pragma mark -
#pragma mark Coding Support

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
        title = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"title"] copy];
        link = [[aDecoder decodeObjectOfClass:[FDPLink class] forKey:@"link"] retain];
        links = [[aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [FDPLink class], nil] forKey:@"links"] mutableCopy];
        feedDescription = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"feedDescription"] copy];
        pubDate = [[aDecoder decodeObjectOfClass:[NSDate class] forKey:@"pubDate"] copy];
        items = [[aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [FDPItem class], nil] forKey:@"items"] mutableCopy];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:title forKey:@"title"];
	[aCoder encodeObject:link forKey:@"link"];
	[aCoder encodeObject:links forKey:@"links"];
	[aCoder encodeObject:feedDescription forKey:@"feedDescription"];
	[aCoder encodeObject:pubDate forKey:@"pubDate"];
	[aCoder encodeObject:items forKey:@"items"];
}
@end
