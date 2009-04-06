//
//  FPFeed.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPFeed.h"
#import "FPFeed_private.h"

static NSDictionary *kNamespaceMap;

@interface FPFeed ()
- (NSString *)mappedNamespace:(NSString *)namespaceURI;
- (NSString *)qualifiedName:(NSString *)name inNamespace:(NSString *)namespaceURI;
- (void)abdicateParsing:(NSXMLParser *)parser;
@end

@implementation FPFeed
@synthesize title, link, description, pubDate;

+ (void)initialize {
	if (self == [FPFeed class]) {
		kNamespaceMap = [[NSDictionary alloc] initWithObjectsAndKeys:
							@"atom",    @"http://www.w3.org/2005/Atom",
							@"dc",      @"http://purl.org/dc/elements/1.1/",
							@"content", @"http://purl.org/rss/1.0/modules/content/",
							nil];
	}
}

- (id)initWithFeedType:(FPFeedType)type parser:(FPParser *)parser {
	if (self = [super init]) {
		feedParser = parser;
		switch (type) {
			case FPFeedTypeRSS:
				feedNamespace = @"rss";
				break;
			case FPFeedTypeAtom:
				feedNamespace = @"atom";
				break;
		}
	}
	return self;
}

- (NSString *)mappedNamespace:(NSString *)namespaceURI {
	if ([namespaceURI isEqualToString:@""] ){
		return feedNamespace;
	} else {
		return [kNamespaceMap objectForKey:namespaceURI];
	}
}

- (NSString *)qualifiedName:(NSString *)name inNamespace:(NSString *)namespaceURI {
	NSString *ns = ([self mappedNamespace:namespaceURI] ?: @"");
	return [NSString stringWithFormat:@"%@:%@", ns, name];
}

- (void)abdicateParsing:(NSXMLParser *)parser {
	[parser setDelegate:feedParser];
	feedParser = nil;
}

- (void)dealloc {
	[feedNamespace release];
	[title release];
	[link release];
	[description release];
	[pubDate release];
	[super dealloc];
}

#pragma mark XML Parser methods

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	feedParser = nil;
	[parser abortParsing];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	NSString *qName = [self qualifiedName:elementName inNamespace:namespaceURI];
	if ([qName isEqualToString:@"rss:channel"] || [qName isEqualToString:@"atom:feed"]) {
		[self abdicateParsing:parser];
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	NSString *ns = [self mappedNamespace:namespaceURI];
	SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@_%@", ns, elementName]);
	if ([self respondsToSelector:sel]) {
		[self performSelector:sel withObject:attributeDict];
	} else if ([namespaceURI isEqualToString:@""]) {
		// no un-qualified names are allowed
		[parser abortParsing];
	}
}
@end
