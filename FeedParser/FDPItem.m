//
//  FDPItem.m
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

#import "FDPItem.h"
#import "FDPLink.h"
#import "FDPEnclosure.h"
#import "FDPCategory.h"
#import "NSDate_FeedParserExtensions.h"

@interface FDPItem ()
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
- (void)rss_category:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser;
@end

@implementation FDPItem
@synthesize title, link, links, guid, description, content, pubDate, author, enclosures, categories;
@synthesize creator;

+ (void)initialize {
	if (self == [FDPItem class]) {
		[self registerRSSHandler:@selector(setTitle:) forElement:@"title" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setAuthor:) forElement:@"author" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_link:attributes:parser:) forElement:@"link" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setGuid:) forElement:@"guid" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(setDescription:) forElement:@"description" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_pubDate:attributes:parser:) forElement:@"pubDate" type:FDPXMLParserTextElementType];
		[self registerRSSHandler:@selector(rss_enclosure:parser:) forElement:@"enclosure" type:FDPXMLParserSkipElementType];
        [self registerRSSHandler:@selector(rss_category:attributes:parser:) forElement:@"category" type:FDPXMLParserTextElementType];
		for (NSString *key in [NSArray arrayWithObjects:@"comments", @"source", nil]) {
			[self registerRSSHandler:NULL forElement:key type:FDPXMLParserSkipElementType];
		}
		// Atom
		[self registerAtomHandler:@selector(atom_link:parser:) forElement:@"link" type:FDPXMLParserSkipElementType];
		// DublinCore
		[self registerTextHandler:@selector(setCreator:) forElement:@"creator" namespaceURI:kFDPXMLParserDublinCoreNamespaceURI];
		// Content
		[self registerTextHandler:@selector(setContent:) forElement:@"encoded" namespaceURI:kFDPXMLParserContentNamespaceURI];
	}
}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI {
	if (self = [super initWithBaseNamespaceURI:namespaceURI]) {
		links = [[NSMutableArray alloc] init];
		enclosures = [[NSMutableArray alloc] init];
        categories = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)rss_pubDate:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	self.pubDate = [NSDate fdp_dateWithRFC822:textValue];
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

- (void)rss_enclosure:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	NSString *url = [attributes objectForKey:@"url"];
	NSString *type = [attributes objectForKey:@"type"];
	NSString *lengthStr = [attributes objectForKey:@"length"];
	if (url == nil || type == nil || lengthStr == nil) return; // sanity check
	NSUInteger length = [lengthStr integerValue];
	FDPEnclosure *anEnclosure = [[FDPEnclosure alloc] initWithURL:url length:length type:type];
	[enclosures addObject:anEnclosure];
	[anEnclosure release];
}


- (void)rss_category:(NSString *)textValue attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
    NSString *domain = [attributes objectForKey:@"domain"];
    FDPCategory *aCategory = [[FDPCategory alloc] initWithDomain:domain value:textValue];
    [categories addObject:aCategory];
    [aCategory release];
}

- (NSString *)content {
	return (content ?: description);
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FDPItem class]]) return NO;
	FDPItem *other = (FDPItem *)anObject;
	return ((title       == other->title       || [title       isEqualToString:other->title])       &&
			(link        == other->link        || [link        isEqual:other->link])                &&
			(links       == other->links       || [links       isEqualToArray:other->links])        &&
			(guid        == other->guid        || [guid        isEqualToString:other->guid])        &&
			(description == other->description || [description isEqualToString:other->description]) &&
			(content     == other->content     || [content     isEqualToString:other->content])     &&
			(pubDate     == other->pubDate     || [pubDate     isEqual:other->pubDate])             &&
			(creator     == other->creator     || [creator     isEqualToString:other->creator])     &&
			(author      == other->author      || [author      isEqualToString:other->author])      &&
			(enclosures  == other->enclosures  || [enclosures  isEqualToArray:other->enclosures])   &&
            (categories  == other->categories  || [categories  isEqualToArray:other->categories]));
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
    [categories release];
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
        guid = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"guid"] copy];
        description = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"description"] copy];
        content = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"content"] copy];
        pubDate = [[aDecoder decodeObjectOfClass:[NSDate class] forKey:@"pubDate"] copy];
        creator = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"creator"] copy];
        author = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"author"] copy];
        enclosures = [[aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [FDPEnclosure class], nil] forKey:@"enclosures"] mutableCopy];
        categories = [[aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [FDPCategory class], nil] forKey:@"categories"] mutableCopy] ?: [[NSMutableArray alloc] init];
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
    [aCoder encodeObject:categories forKey:@"categories"];
}
@end
