//
//  FPItem.m
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

#import "FPItem.h"
#import "FPLink.h"
#import "FPEnclosure.h"
#import "NSDate_FeedParserExtensions.h"

@interface FPItem ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *guid;
@property (nonatomic, copy, readwrite) NSString *description;
@property (nonatomic, copy, readwrite) NSString *content;
@property (nonatomic, copy, readwrite) NSString *creator;
@property (nonatomic, copy, readwrite) NSDate *pubDate;
@property (nonatomic, copy, readwrite) NSString *author;
- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_enclosure:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
@end

@implementation FPItem
@synthesize title, link, links, guid, description, content, pubDate, author, enclosures;
@synthesize creator;

+ (void)initialize {
	if (self == [FPItem class]) {
		[self registerRSSHandler:@selector(setTitle:) forElement:@"title" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setAuthor:) forElement:@"author" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_link:attributes:parser:) forElement:@"link" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setGuid:) forElement:@"guid" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setDescription:) forElement:@"description" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" type:FPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_enclosure:parser:) forElement:@"enclosure" type:FPXMLParserSkipElementType];
		for (NSString *key in [NSArray arrayWithObjects:@"category", @"comments", @"source", nil]) {
			[self registerRSSHandler:NULL forElement:key type:FPXMLParserSkipElementType];
		}
		// Atom
		[self registerAtomHandler:@selector(atom_link:parser:) forElement:@"link" type:FPXMLParserSkipElementType];
		// DublinCore
		[self registerTextHandler:@selector(setCreator:) forElement:@"creator" namespaceURI:kFPXMLParserDublinCoreNamespaceURI];
		// Content
		[self registerTextHandler:@selector(setContent:) forElement:@"encoded" namespaceURI:kFPXMLParserContentNamespaceURI];
	}
}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI {
	if (self = [super initWithBaseNamespaceURI:namespaceURI]) {
		links = [[NSMutableArray alloc] init];
		enclosures = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSDate *date = [NSDate dateWithRFC822:textValue];
	self.pubDate = date;
	if (date == nil) [self abortParsing:parser withFormat:@"could not parse pubDate '%@'", textValue];
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

- (void)rss_enclosure:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *url = [attributes objectForKey:@"url"];
	NSString *type = [attributes objectForKey:@"type"];
	NSString *lengthStr = [attributes objectForKey:@"length"];
	if (url == nil || type == nil || lengthStr == nil) return; // sanity check
	NSUInteger length = [lengthStr integerValue];
	FPEnclosure *anEnclosure = [[FPEnclosure alloc] initWithURL:url length:length type:type];
	[enclosures addObject:anEnclosure];
	[anEnclosure release];
}

- (NSString *)content {
	return (content ?: description);
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPItem class]]) return NO;
	FPItem *other = (FPItem *)anObject;
	return ((title       == other->title       || [title       isEqualToString:other->title])       &&
			(link        == other->link        || [link        isEqual:other->link])                &&
			(links       == other->links       || [links       isEqualToArray:other->links])        &&
			(guid        == other->guid        || [guid        isEqualToString:other->guid])        &&
			(description == other->description || [description isEqualToString:other->description]) &&
			(content     == other->content     || [content     isEqualToString:other->content])     &&
			(pubDate     == other->pubDate     || [pubDate     isEqual:other->pubDate])             &&
			(creator     == other->creator     || [creator     isEqualToString:other->creator])     &&
			(author      == other->author      || [author      isEqualToString:other->author])      &&
			(enclosures  == other->enclosures  || [enclosures  isEqualToArray:other->enclosures]));
}

- (void)dealloc {
	[title release];
	[link release];
	[links release];
	[guid release];
	[description release];
	[content release];
	[pubDate release];
	[creator release];
	[author release];
	[enclosures release];
	[super dealloc];
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		title = [[aDecoder decodeObjectForKey:@"title"] copy];
		link = [[aDecoder decodeObjectForKey:@"link"] retain];
		links = [[aDecoder decodeObjectForKey:@"links"] mutableCopy];
		guid = [[aDecoder decodeObjectForKey:@"guid"] copy];
		description = [[aDecoder decodeObjectForKey:@"description"] copy];
		content = [[aDecoder decodeObjectForKey:@"content"] copy];
		pubDate = [[aDecoder decodeObjectForKey:@"pubDate"] copy];
		creator = [[aDecoder decodeObjectForKey:@"creator"] copy];
		author = [[aDecoder decodeObjectForKey:@"author"] copy];
		enclosures = [[aDecoder decodeObjectForKey:@"enclosures"] mutableCopy];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:title forKey:@"title"];
	[aCoder encodeObject:link forKey:@"link"];
	[aCoder encodeObject:links forKey:@"links"];
	[aCoder encodeObject:guid forKey:@"guid"];
	[aCoder encodeObject:description forKey:@"description"];
	[aCoder encodeObject:content forKey:@"content"];
	[aCoder encodeObject:pubDate forKey:@"pubDate"];
	[aCoder encodeObject:creator forKey:@"creator"];
	[aCoder encodeObject:author forKey:@"author"];
	[aCoder encodeObject:enclosures forKey:@"enclosures"];
}
@end
