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

@property (readwrite, copy,   nonatomic) NSString *title;
@property (readwrite, strong, nonatomic) FPLink *link;
@property (readwrite, strong, nonatomic) NSMutableArray *mutableLinks;
@property (readwrite, copy,   nonatomic) NSString *guid;
@property (readwrite, copy,   nonatomic) NSString *description;
@property (readwrite, copy,   nonatomic) NSString *content;
@property (readwrite, copy,   nonatomic) NSString *creator;
@property (readwrite, copy,   nonatomic) NSDate *pubDate;
@property (readwrite, copy,   nonatomic) NSString *author;
@property (readwrite, strong, nonatomic) NSMutableArray *mutableEnclosures;

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_link:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)atom_link:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
- (void)rss_enclosure:(NSDictionary *)attributes parser:(NSXMLParser *)parser;

@end

@implementation FPItem

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
		self.mutableLinks = [[NSMutableArray alloc] init];
		self.mutableEnclosures = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSArray *)links {
	return self.mutableLinks;
}

- (void)setLinks:(NSArray *)links {
	self.mutableLinks = [links mutableCopy];
}

- (NSArray *)enclosures {
	return self.mutableEnclosures;
}

- (void)setEnclosures:(NSArray *)enclosures {
	self.mutableEnclosures = [enclosures mutableCopy];
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	self.pubDate = [NSDate dateWithRFC822:textValue];
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
	if (href == nil) { // sanity check
		return;
	}
	FPLink *aLink = [[FPLink alloc] initWithHref:href rel:[attributes objectForKey:@"rel"] type:[attributes objectForKey:@"type"]
										   title:[attributes objectForKey:@"title"]];
	if (self.link == nil && [aLink.rel isEqualToString:@"alternate"]) {
		self.link = aLink;
	}
	[self.mutableLinks addObject:aLink];
}

- (void)rss_enclosure:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *url = [attributes objectForKey:@"url"];
	NSString *type = [attributes objectForKey:@"type"];
	NSString *lengthStr = [attributes objectForKey:@"length"];
	if (url == nil || type == nil || lengthStr == nil) { // sanity check
		return;
	}
	NSUInteger length = [lengthStr integerValue];
	FPEnclosure *anEnclosure = [[FPEnclosure alloc] initWithURL:url length:length type:type];
	[self.mutableEnclosures addObject:anEnclosure];
}

- (NSString *)content {
	return (_content ? : self.description);
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPItem class]]) {
		return NO;
	}
	FPItem *other = (FPItem *)anObject;
	return ((self.title == other.title || [self.title isEqualToString:other.title]) &&
			(self.link == other.link || [self.link isEqual:other.link]) &&
			(self.links == other.links || [self.links isEqualToArray:other.links]) &&
			(self.guid == other.guid || [self.guid isEqualToString:other.guid]) &&
			(self.description == other.description || [self.description isEqualToString:other.description]) &&
			(self.content == other.content || [self.content isEqualToString:other.content]) &&
			(self.pubDate == other.pubDate || [self.pubDate isEqual:other.pubDate]) &&
			(self.creator == other.creator || [self.creator isEqualToString:other.creator]) &&
			(self.author == other.author || [self.author isEqualToString:other.author]) &&
			(self.enclosures == other.enclosures || [self.enclosures isEqualToArray:other.enclosures]));
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.title				= [aDecoder decodeObjectForKey:@"title"];
		self.link				= [aDecoder decodeObjectForKey:@"link"];
		self.links				= [aDecoder decodeObjectForKey:@"links"];
		self.guid				= [aDecoder decodeObjectForKey:@"guid"];
		self.description		= [aDecoder decodeObjectForKey:@"description"];
		self.content			= [aDecoder decodeObjectForKey:@"content"];
		self.pubDate			= [aDecoder decodeObjectForKey:@"pubDate"];
		self.creator			= [aDecoder decodeObjectForKey:@"creator"];
		self.author				= [aDecoder decodeObjectForKey:@"author"];
		self.enclosures			= [aDecoder decodeObjectForKey:@"enclosures"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.title			forKey:@"title"];
	[aCoder encodeObject:self.link			forKey:@"link"];
	[aCoder encodeObject:self.links			forKey:@"links"];
	[aCoder encodeObject:self.guid			forKey:@"guid"];
	[aCoder encodeObject:self.description	forKey:@"description"];
	[aCoder encodeObject:self.content		forKey:@"content"];
	[aCoder encodeObject:self.pubDate		forKey:@"pubDate"];
	[aCoder encodeObject:self.creator		forKey:@"creator"];
	[aCoder encodeObject:self.author		forKey:@"author"];
	[aCoder encodeObject:self.enclosures	forKey:@"enclosures"];
}
@end
