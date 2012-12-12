//
//  FPFeed.m
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

#import "FPFeed.h"
#import "FPXMLParser_Private.h"
#import "FPItem.h"
#import "FPLink.h"
#import "FPParser.h"
#import "NSDate_FeedParserExtensions.h"

@interface FPFeed ()

@property (readwrite, copy, nonatomic) NSString *title;
@property (readwrite, copy, nonatomic) FPLink *link;
@property (readwrite, strong, nonatomic) NSMutableArray *mutableLinks;
@property (readwrite, copy, nonatomic) NSString *feedDescription;
@property (readwrite, copy, nonatomic) NSDate *pubDate;
@property (readwrite, strong, nonatomic) NSMutableArray *mutableItems;

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_item:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser;

@end

@implementation FPFeed

+ (void)initialize {
	if (self == [FPFeed class]) {
		[self registerRSSHandler:@selector(setTitle:) forElement:@"title" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_link:attributes:parser:) forElement:@"link" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setFeedDescription:) forElement:@"description" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" type:FPXMLParserTextElementType];
		for (NSString *key in [NSArray arrayWithObjects:
							   @"language", @"copyright", @"managingEditor", @"webMaster", @"lastBuildDate", @"category",
							   @"generator", @"docs", @"cloud", @"ttl", @"image", @"rating", @"textInput", @"skipHours", @"skipDays", nil]) {
			[self registerRSSHandler:NULL forElement:key type:FPXMLParserSkipElementType];
		}
		[self registerRSSHandler:@selector(rss_item:parser:) forElement:@"item" type:FPXMLParserStreamElementType];
		
		// atom elements
		[self registerAtomHandler:@selector(atom_link:parser:) forElement:@"link" type:FPXMLParserSkipElementType];
	}
}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI {
	if (self = [super initWithBaseNamespaceURI:namespaceURI]) {
		self.mutableItems = [[NSMutableArray alloc] init];
		self.mutableLinks = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSArray *)items {
	return self.mutableItems;
}

- (void)setItems:(NSArray *)items {
	self.mutableItems = [items mutableCopy];
}

- (NSArray *)links {
	return self.mutableLinks;
}

- (void)setLinks:(NSArray *)links {
	self.mutableLinks = [links mutableCopy];
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSDate *date = [NSDate dateWithRFC822:textValue];
	self.pubDate = date;
	if (date == nil) [self abortParsing:parser withFormat:@"could not parse pubDate '%@'", textValue];
}

- (void)rss_item:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FPItem *item = [[FPItem alloc] initWithBaseNamespaceURI:self.baseNamespaceURI];
	[item acceptParsing:parser];
	[self.mutableItems addObject:item];
}

- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	FPLink *aLink = [[FPLink alloc] initWithHref:textValue rel:@"alternate" type:nil title:nil];
	if (self.link == nil) {
		self.link = aLink;
	}
	[self.mutableLinks addObject:aLink];
}

- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *href = [attributes objectForKey:@"href"];
	if (href == nil) return; // sanity check
	FPLink *aLink = [[FPLink alloc] initWithHref:href rel:[attributes objectForKey:@"rel"] type:[attributes objectForKey:@"type"]
										   title:[attributes objectForKey:@"title"]];
	if (self.link == nil && [aLink.rel isEqualToString:@"alternate"]) {
		self.link = aLink;
	}
	[self.mutableLinks addObject:aLink];
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPFeed class]]) return NO;
	FPFeed *other = (FPFeed *)anObject;
	return ((self.title == other.title || [self.title isEqualToString:other.title]) &&
			(self.link == other.link || [self.link isEqual:other.link]) &&
			(self.links == other.links || [self.links isEqualToArray:other.links]) &&
			(self.feedDescription == other.feedDescription || [self.feedDescription isEqualToString:other.feedDescription]) &&
			(self.pubDate == other.pubDate || [self.pubDate isEqual:other.pubDate]) &&
			(self.items == other.items || [self.items isEqualToArray:other.items]));
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.title				= [aDecoder decodeObjectForKey:@"title"];
		self.link				= [aDecoder decodeObjectForKey:@"link"];
		self.links				= [aDecoder decodeObjectForKey:@"links"];
		self.feedDescription	= [aDecoder decodeObjectForKey:@"feedDescription"];
		self.pubDate			= [aDecoder decodeObjectForKey:@"pubDate"];
		self.items				= [aDecoder decodeObjectForKey:@"items"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.title				forKey:@"title"];
	[aCoder encodeObject:self.link				forKey:@"link"];
	[aCoder encodeObject:self.links				forKey:@"links"];
	[aCoder encodeObject:self.feedDescription	forKey:@"feedDescription"];
	[aCoder encodeObject:self.pubDate			forKey:@"pubDate"];
	[aCoder encodeObject:self.items				forKey:@"items"];
}
@end
