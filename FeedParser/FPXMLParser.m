//
//  FPXMLParser.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPXMLParser.h"
#import "FPXMLPair.h"
#import <objc/message.h>
#import <stdarg.h>

NSString * const kFPXMLParserAtomNamespaceURI = @"http://www.w3.org/2005/Atom";
NSString * const kFPXMLParserDublinCoreNamespaceURI = @"http://purl.org/dc/elements/1.1/";
NSString * const kFPXMLParserContentNamespaceURI = @"http://web.resource.org/rss/1.0/modules/content/";

static NSMutableDictionary *kHandlerMap;

void (*handleTextValue)(id, SEL, NSString*, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSString*, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleStreamElement)(id, SEL, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSDictionary*, NSXMLParser*))objc_msgSend;

@implementation FPXMLParser
+ (void)initialize {
	if (self == [FPXMLParser class]) {
		kHandlerMap = (NSMutableDictionary *)CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	}
}

// if selector is NULL then just ignore this element rather than raising an error
+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FPXMLParserElementType)type {
	NSMutableDictionary *handlers = [kHandlerMap objectForKey:self];
	if (handlers == nil) {
		handlers = [NSMutableDictionary dictionary];
		CFDictionarySetValue((CFMutableDictionaryRef)kHandlerMap, self, handlers);
	}
	FPXMLPair *keyPair = [FPXMLPair pairWithFirst:elementName second:namespaceURI];
	FPXMLPair *valuePair = [FPXMLPair pairWithFirst:NSStringFromSelector(selector) second:[NSNumber numberWithInt:type]];
	[handlers setObject:valuePair forKey:keyPair];
}

- (id)initWithParser:(NSXMLParser *)parser baseNamespaceURI:(NSString *)namespaceURI {
	if (self = [self init]) {
		baseNamespaceURI = [namespaceURI copy];
		// assume that the old delegate was an FPXMLParser
		// if not, then something is broken
		parentParser = (FPXMLParser *)[parser delegate];
		[parser setDelegate:self];
	}
	return self;
}

- (id)init {
	if (self = [super init]) {
		handlers = [[kHandlerMap objectForKey:[self class]] retain];
		currentElementType = FPXMLParserStreamElementType;
		parseDepth = 1;
	}
	return self;
}

- (void)abortParsing:(NSXMLParser *)parser {
	[self abortParsing:parser withString:nil];
}

- (void)abortParsing:(NSXMLParser *)parser withFormat:(NSString *)description, ... {
	va_list valist;
	va_start(valist, description);
	NSString *desc = [[[NSString alloc] initWithFormat:description arguments:valist] autorelease];
	va_end(valist);
	return [self abortParsing:parser withString:desc];
}

- (void)abortParsing:(NSXMLParser *)parser withString:(NSString *)description {
	if (parentParser != nil) {
		FPXMLParser *parent = parentParser;
		parentParser = nil;
		[parent abortParsing:parser withString:description];
	} else {
		[parser setDelegate:nil];
		[parser abortParsing];
	}
}

- (void)abdicateParsing:(NSXMLParser *)parser {
	[parser setDelegate:parentParser];
	parentParser = nil;
}

- (void)dealloc {
	[handlers release];
	[currentTextValue release];
	[currentAttributeDict release];
	[super dealloc];
}

#pragma mark XML Parser methods

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	switch (currentElementType) {
		case FPXMLParserTextElementType:
			[currentTextValue appendString:string];
			break;
		case FPXMLParserStreamElementType:
			if ([string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location != NSNotFound) {
				[self abortParsing:parser withFormat:@"Unexpected text \"%@\" at line %d", string, [parser lineNumber]];
			}
			break;
		case FPXMLParserSkipElementType:
			break;
	}
}

// this method never seems to be called
- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
	if (currentElementType == FPXMLParserTextElementType) {
		[currentTextValue appendString:whitespaceString];
	}
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	switch (currentElementType) {
		case FPXMLParserTextElementType: {
			NSString *str = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
			if (str == nil) {
				// the data isn't valid UTF-8
				// try as ISO-Latin-1. Probably not correct, but at least it will never fail
				str = [[NSString alloc] initWithData:CDATABlock encoding:NSISOLatin1StringEncoding];
			}
			[currentTextValue appendString:str];
			[str release];
			break;
		}
		case FPXMLParserStreamElementType:
			[self abortParsing:parser withFormat:@"Unexpected CDATA at line %d", [parser lineNumber]];
			break;
		case FPXMLParserSkipElementType:
			break;
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if (baseNamespaceURI == nil) {
		baseNamespaceURI = [namespaceURI copy];
	}
	switch (currentElementType) {
		case FPXMLParserTextElementType:
			[self abortParsing:parser];
			break;
		case FPXMLParserStreamElementType: {
			FPXMLPair *keyPair = [FPXMLPair pairWithFirst:elementName second:namespaceURI];
			FPXMLPair *handler = [handlers objectForKey:keyPair];
			if (handler != nil) {
				SEL selector = NSSelectorFromString((NSString *)handler.first);
				FPXMLParserElementType type = (FPXMLParserElementType)[(NSNumber *)handler.second intValue];
				currentElementType = type;
				switch (type) {
					case FPXMLParserStreamElementType:
						if (selector != NULL) {
							handleStreamElement(self, selector, attributeDict, parser);
							if ([parser delegate] == self) parseDepth++;
						}
						break;
					case FPXMLParserTextElementType:
						[currentTextValue release];
						currentTextValue = [[NSMutableString alloc] init];
						[currentAttributeDict release];
						currentAttributeDict = [attributeDict copy];
						currentHandlerSelector = selector;
						break;
					case FPXMLParserSkipElementType:
						skipDepth = 1;
						break;
				}
			} else if ([namespaceURI isEqualToString:baseNamespaceURI]) {
				[self abortParsing:parser];
			} else {
				// element is unrecognized and out of our namespace. Skip its content
				currentElementType = FPXMLParserSkipElementType;
				skipDepth = 1;
			}
			break;
		}
		case FPXMLParserSkipElementType:
			skipDepth++;
			break;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	switch (currentElementType) {
		case FPXMLParserTextElementType: {
			if (currentHandlerSelector != NULL) {
				handleTextValue(self, currentHandlerSelector, currentTextValue, currentAttributeDict, parser);
			}
			[currentTextValue release];
			currentTextValue = nil;
			[currentAttributeDict release];
			currentAttributeDict = nil;
			currentElementType = FPXMLParserStreamElementType;
			break;
		}
		case FPXMLParserStreamElementType:
			parseDepth--;
			if (parseDepth == 0) {
				[self abdicateParsing:parser];
			}
			break;
		case FPXMLParserSkipElementType:
			skipDepth--;
			if (skipDepth == 0) {
				currentElementType = FPXMLParserStreamElementType;
			}
			break;
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[self abortParsing:parser];
}
@end
