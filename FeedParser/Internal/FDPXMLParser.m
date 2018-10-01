//
//  FDPXMLParser.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
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

#import "FDPXMLParser.h"
#import "FDPXMLPair.h"
#import "FDPExtensionNode.h"
#import "FDPExtensionElementNode.h"
#import "FPExtensionElementNode_Private.h"
#import <objc/message.h>
#import <stdarg.h>

NSString * const kFDPXMLParserAtomNamespaceURI = @"http://www.w3.org/2005/Atom";
NSString * const kFDPXMLParserDublinCoreNamespaceURI = @"http://purl.org/dc/elements/1.1/";
NSString * const kFDPXMLParserContentNamespaceURI = @"http://purl.org/rss/1.0/modules/content/";

NSString * const kFPXMLParserAtomNamespaceURI = kFDPXMLParserAtomNamespaceURI;
NSString * const kFPXMLParserDublinCoreNamespaceURI = kFDPXMLParserDublinCoreNamespaceURI;
NSString * const kFPXMLParserContentNamespaceURI = kFDPXMLParserContentNamespaceURI;

static NSMutableDictionary *kHandlerMap;

void (*handleTextValue)(id, SEL, NSString*, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSString*, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleStreamElement)(id, SEL, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleSkipElement)(id, SEL, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleExtensionElement)(id, SEL, FDPExtensionNode *node, NSXMLParser*) = (void(*)(id, SEL, FDPExtensionNode*, NSXMLParser*))objc_msgSend;

@interface FDPXMLParser ()
+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FDPXMLParserElementType)type;
@end

@implementation FDPXMLParser
@synthesize extensionElements;
+ (void)initialize {
	if (self == [FDPXMLParser class]) {
		kHandlerMap = (NSMutableDictionary *)CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	}
}

+ (void)registerRSSHandler:(SEL)selector forElement:(NSString *)elementName type:(FDPXMLParserElementType)type {
	[self registerHandler:selector forElement:elementName namespaceURI:@"" type:type];
}

+ (void)registerAtomHandler:(SEL)selector forElement:(NSString *)elementName type:(FDPXMLParserElementType)type {
	[self registerHandler:selector forElement:elementName namespaceURI:kFDPXMLParserAtomNamespaceURI type:type];
}

+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI {
	[self registerHandler:selector forElement:elementName namespaceURI:namespaceURI type:FDPXMLParserExtensionElementType];
}

+ (void)registerTextHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI {
	[self registerHandler:selector forElement:elementName namespaceURI:namespaceURI type:FDPXMLParserTextExtensionElementType];
}

// if selector is NULL then just ignore this element rather than raising an error
+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FDPXMLParserElementType)type {
	NSMutableDictionary *handlers = [kHandlerMap objectForKey:self];
	if (handlers == nil) {
		handlers = [NSMutableDictionary dictionary];
		CFDictionarySetValue((CFMutableDictionaryRef)kHandlerMap, self, handlers);
	}
	FDPXMLPair *keyPair = [FDPXMLPair pairWithFirst:elementName second:namespaceURI];
	FDPXMLPair *valuePair = [FDPXMLPair pairWithFirst:NSStringFromSelector(selector) second:[NSNumber numberWithInt:type]];
	[handlers setObject:valuePair forKey:keyPair];
}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI {
	if (self = [self init]) {
		baseNamespaceURI = [namespaceURI copy];
	}
	return self;
}

- (id)init {
	if (self = [super init]) {
		extensionElements = [[NSMutableArray alloc] init];
		handlers = [[kHandlerMap objectForKey:[self class]] retain];
		currentElementType = FDPXMLParserStreamElementType;
		parseDepth = 1;
	}
	return self;
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
		// we may be owned by our parent. If this is true, ensure we don't die instantly
		[[self retain] autorelease];
		id<FDPXMLParserProtocol> parent = parentParser;
		parentParser = nil;
		[parent abortParsing:parser withString:description];
	} else {
		[parser setDelegate:nil];
		[parser abortParsing];
	}
}

- (void)abdicateParsing:(NSXMLParser *)parser {
	[parser setDelegate:parentParser];
	[parentParser resumeParsing:parser fromChild:self];
	parentParser = nil;
}

- (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI {
	if (namespaceURI == nil) {
		return self.extensionElements;
	} else {
		return [self extensionElementsWithXMLNamespace:namespaceURI elementName:nil];
	}
}

- (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI elementName:(NSString *)elementName {
	NSMutableArray *ary = [NSMutableArray arrayWithCapacity:[extensionElements count]];
	for (FDPExtensionNode *node in extensionElements) {
		if ([node.namespaceURI isEqualToString:namespaceURI] &&
			(elementName == nil || [node.name isEqualToString:elementName])) {
			[ary addObject:node];
		}
	}
	return ary;
}

- (void)dealloc {
	[extensionElements release];
	[handlers release];
	[currentTextValue release];
	[currentAttributeDict release];
	[super dealloc];
}

#pragma mark XML Parser methods

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	switch (currentElementType) {
		case FDPXMLParserTextElementType:
			[currentTextValue appendString:string];
			break;
		case FDPXMLParserStreamElementType:
			if ([string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location != NSNotFound) {
				[self abortParsing:parser withFormat:@"Unexpected text \"%@\" at line %d", string, [parser lineNumber]];
			}
			break;
		case FDPXMLParserSkipElementType:
            break;
        case FDPXMLParserExtensionElementType:
        case FDPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FDPXMLParserExtensionElementType on generic FDPXMLParser");
			break;
	}
}

// this method never seems to be called
- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
	if (currentElementType == FDPXMLParserTextElementType) {
		[currentTextValue appendString:whitespaceString];
	}
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	switch (currentElementType) {
		case FDPXMLParserTextElementType: {
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
		case FDPXMLParserStreamElementType:
			[self abortParsing:parser withFormat:@"Unexpected CDATA at line %d", [parser lineNumber]];
			break;
		case FDPXMLParserSkipElementType:
            break;
        case FDPXMLParserExtensionElementType:
        case FDPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FDPXMLParserExtensionElementType on generic FDPXMLParser");
			break;
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if (baseNamespaceURI == nil) {
		baseNamespaceURI = [namespaceURI copy];
	}
	switch (currentElementType) {
		case FDPXMLParserTextElementType:
			[self abortParsing:parser];
			break;
		case FDPXMLParserStreamElementType: {
			FDPXMLPair *keyPair = [FDPXMLPair pairWithFirst:elementName second:namespaceURI];
			FDPXMLPair *handler = [handlers objectForKey:keyPair];
			if (handler != nil) {
				SEL selector = NSSelectorFromString((NSString *)handler.first);
				currentElementType = (FDPXMLParserElementType)[(NSNumber *)handler.second intValue];
				switch (currentElementType) {
					case FDPXMLParserStreamElementType:
						if (selector != NULL) {
							handleStreamElement(self, selector, attributeDict, parser);
						}
						if ([parser delegate] == self) parseDepth++;
						break;
					case FDPXMLParserTextElementType:
						[currentTextValue release];
						currentTextValue = [[NSMutableString alloc] init];
						[currentAttributeDict release];
						currentAttributeDict = [attributeDict copy];
						currentHandlerSelector = selector;
						break;
					case FDPXMLParserSkipElementType:
						if (selector != NULL) {
							handleSkipElement(self, selector, attributeDict, parser);
						}
						if ([parser delegate] == self) {
							skipDepth++;
						} else {
							// if the skip handler changed the delegate, then when we gain control
							// again we should be in the stream mode.
							// note that this is an exceptional condition, as skip handlers are not expected
							// to change the delegate. If the handler wants to do that it should use a stream handler.
							currentElementType = FDPXMLParserStreamElementType;
						}
						break;
					case FDPXMLParserExtensionElementType:
					case FDPXMLParserTextExtensionElementType:
						;
						currentHandlerSelector = selector;
						FDPExtensionElementNode *node = [[FDPExtensionElementNode alloc] initWithElementName:elementName
																							  namespaceURI:namespaceURI
																							 qualifiedName:qualifiedName
																								attributes:attributeDict];
						[node acceptParsing:parser];
						[extensionElements addObject:node];
						[node release];
						break;
				}
			} else if ([namespaceURI isEqualToString:baseNamespaceURI]) {
				[self abortParsing:parser];
			} else if (![namespaceURI isEqualToString:kFDPXMLParserAtomNamespaceURI] && ![namespaceURI isEqualToString:@""]) {
				// element is unknown and belongs to neither the Atom nor RSS namespaces
				FDPExtensionElementNode *node = [[FDPExtensionElementNode alloc] initWithElementName:elementName namespaceURI:namespaceURI
																					 qualifiedName:qualifiedName attributes:attributeDict];
				[node acceptParsing:parser];
				[extensionElements addObject:node];
				[node release];
			} else {
				// this is an unknown element outside of the base namespace, but still belonging to either RSS or Atom
				// As this is not in our base namespace, we are not required to handle it.
				// Do not use the extension mechanism for this because of forward-compatibility issues. If we use the
				// extension mechanism, then later add support for the element, code relying on the extension mechanism
				// would stop working.
				currentElementType = FDPXMLParserSkipElementType;
				skipDepth = 1;
			}
			break;
		}
		case FDPXMLParserSkipElementType:
			skipDepth++;
			break;
		case FDPXMLParserExtensionElementType:
		case FDPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FDPXMLParserExtensionElementType on generic FDPXMLParser");
			break;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	switch (currentElementType) {
		case FDPXMLParserTextElementType: {
			if (currentHandlerSelector != NULL) {
				handleTextValue(self, currentHandlerSelector, currentTextValue, currentAttributeDict, parser);
			}
			currentHandlerSelector = NULL;
			[currentTextValue release];
			currentTextValue = nil;
			[currentAttributeDict release];
			currentAttributeDict = nil;
			currentElementType = FDPXMLParserStreamElementType;
			break;
		}
		case FDPXMLParserStreamElementType:
			parseDepth--;
			if (parseDepth == 0) {
				[self abdicateParsing:parser];
			}
			break;
		case FDPXMLParserSkipElementType:
			skipDepth--;
			if (skipDepth == 0) {
				currentElementType = FDPXMLParserStreamElementType;
			}
			break;
        case FDPXMLParserExtensionElementType:
        case FDPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FDPXMLParserExtensionElementType on generic FDPXMLParser");
            break;
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[self abortParsing:parser];
}

#pragma mark FDPXMLParserProtocol methods

- (void)acceptParsing:(NSXMLParser *)parser {
	parentParser = (id<FDPXMLParserProtocol>)[parser delegate];
	[parser setDelegate:self];
}

- (void)abortParsing:(NSXMLParser *)parser {
	[self abortParsing:parser withString:nil];
}

- (void)resumeParsing:(NSXMLParser *)parser fromChild:(id<FDPXMLParserProtocol>)child {
	if (currentElementType == FDPXMLParserExtensionElementType ||
		currentElementType == FDPXMLParserTextExtensionElementType) {
		NSAssert([child isKindOfClass:[FDPExtensionNode class]], @"resumeParsing: called with unexpected child");
		FDPExtensionNode *node = (FDPExtensionNode *)child;
		if (currentElementType == FDPXMLParserTextExtensionElementType) {
			// validation
			if ([node.children count] > 1 || ([node.children count] == 1 && ![[node.children objectAtIndex:0] isTextNode])) {
				[self abortParsing:parser withFormat:@"Unexpected child elements in node <%@>", node.qualifiedName];
				return;
			}
			if (currentHandlerSelector != NULL) {
				handleTextValue(self, currentHandlerSelector, node.stringValue, node.attributes, parser);
			}
		} else {
			if (currentHandlerSelector != NULL) {
				handleExtensionElement(self, currentHandlerSelector, node, parser);
			}
		}
		currentHandlerSelector = NULL;
		currentElementType = FDPXMLParserStreamElementType;
	}
}

#pragma mark -
#pragma mark Coding Support

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [self init]) {
        baseNamespaceURI = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"baseNamespaceURI"] copy];
		[extensionElements release];
        extensionElements = [[aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [FDPExtensionNode class], nil] forKey:@"extensionElements"] mutableCopy];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:baseNamespaceURI forKey:@"baseNamespaceURI"];
	[aCoder encodeObject:extensionElements forKey:@"extensionElements"];
}
@end
