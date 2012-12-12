//
//  FPXMLParser.m
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

#import "FPXMLParser.h"
#import "FPXMLParser_Private.h"
#import "FPXMLPair.h"
#import "FPExtensionNode.h"
#import "FPExtensionElementNode.h"
#import "FPExtensionElementNode_Private.h"
#import <objc/message.h>
#import <stdarg.h>

NSString * const kFPXMLParserAtomNamespaceURI = @"http://www.w3.org/2005/Atom";
NSString * const kFPXMLParserDublinCoreNamespaceURI = @"http://purl.org/dc/elements/1.1/";
NSString * const kFPXMLParserContentNamespaceURI = @"http://purl.org/rss/1.0/modules/content/";

static NSMutableDictionary *kHandlerMap;

void (*handleTextValue)(id, SEL, NSString*, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSString*, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleStreamElement)(id, SEL, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleSkipElement)(id, SEL, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleExtensionElement)(id, SEL, FPExtensionNode *node, NSXMLParser*) = (void(*)(id, SEL, FPExtensionNode*, NSXMLParser*))objc_msgSend;

@interface FPXMLParser ()

+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FPXMLParserElementType)type;

@end

@implementation FPXMLParser

+ (void)initialize {
	if (self == [FPXMLParser class]) {
		kHandlerMap = (__bridge NSMutableDictionary *) CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	}
}

+ (void)registerRSSHandler:(SEL)selector forElement:(NSString *)elementName type:(FPXMLParserElementType)type {
	[self registerHandler:selector forElement:elementName namespaceURI:@"" type:type];
}

+ (void)registerAtomHandler:(SEL)selector forElement:(NSString *)elementName type:(FPXMLParserElementType)type {
	[self registerHandler:selector forElement:elementName namespaceURI:kFPXMLParserAtomNamespaceURI type:type];
}

+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI {
	[self registerHandler:selector forElement:elementName namespaceURI:namespaceURI type:FPXMLParserExtensionElementType];
}

+ (void)registerTextHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI {
	[self registerHandler:selector forElement:elementName namespaceURI:namespaceURI type:FPXMLParserTextExtensionElementType];
}

// if selector is NULL then just ignore this element rather than raising an error
+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FPXMLParserElementType)type {
	NSMutableDictionary *handlers = [kHandlerMap objectForKey:self];
	if (handlers == nil) {
		handlers = [NSMutableDictionary dictionary];
		CFDictionarySetValue((CFMutableDictionaryRef)kHandlerMap, (const void *)(self), (const void *)handlers);
	}
	FPXMLPair *keyPair = [FPXMLPair pairWithFirst:elementName second:namespaceURI];
	FPXMLPair *valuePair = [FPXMLPair pairWithFirst:NSStringFromSelector(selector) second:[NSNumber numberWithInt:type]];
	[handlers setObject:valuePair forKey:keyPair];
}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI {
	if (self = [self init]) {
		self.baseNamespaceURI = namespaceURI;
	}
	return self;
}

- (id)init {
	if (self = [super init]) {
		self.extensionElements = [[NSMutableArray alloc] init];
		self.handlers = [kHandlerMap objectForKey:[self class]];
		self.currentElementType = FPXMLParserStreamElementType;
		self.parseDepth = 1;
	}
	return self;
}

- (NSArray *)extensionElements {
	return self.mutableExtensionElements;
}

- (void)setExtensionElements:(NSArray *)extensionElements {
	self.mutableExtensionElements = [extensionElements mutableCopy];
}

- (void)abortParsing:(NSXMLParser *)parser withFormat:(NSString *)description, ... {
	va_list valist;
	va_start(valist, description);
	NSString *desc = [[NSString alloc] initWithFormat:description arguments:valist];
	va_end(valist);
	return [self abortParsing:parser withString:desc];
}

- (void)abortParsing:(NSXMLParser *)parser withString:(NSString *)description {
	if (self.parentParser != nil) {
		// we may be owned by our parent. If this is true, ensure we don't die instantly
		id<FPXMLParserProtocol> parent = self.parentParser;
		self.parentParser = nil;
		[parent abortParsing:parser withString:description];
	} else {
		[parser setDelegate:nil];
		[parser abortParsing];
	}
}

- (void)abdicateParsing:(NSXMLParser *)parser {
	[parser setDelegate:self.parentParser];
	[self.parentParser resumeParsing:parser fromChild:self];
	self.parentParser = nil;
}

- (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI {
	if (namespaceURI == nil) {
		return self.extensionElements;
	} else {
		return [self extensionElementsWithXMLNamespace:namespaceURI elementName:nil];
	}
}

- (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI elementName:(NSString *)elementName {
	NSMutableArray *ary = [NSMutableArray arrayWithCapacity:[self.extensionElements count]];
	for (FPExtensionNode *node in self.extensionElements) {
		if ([node.namespaceURI isEqualToString:namespaceURI] &&
			(elementName == nil || [node.name isEqualToString:elementName])) {
			[ary addObject:node];
		}
	}
	return ary;
}

#pragma mark XML Parser methods

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	switch (self.currentElementType) {
		case FPXMLParserTextElementType:
			[self.currentTextValue appendString:string];
			break;
		case FPXMLParserStreamElementType:
			if ([string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location != NSNotFound) {
				[self abortParsing:parser withFormat:@"Unexpected text \"%@\" at line %d", string, [parser lineNumber]];
			}
			break;
		case FPXMLParserSkipElementType:
            break;
        case FPXMLParserExtensionElementType:
        case FPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FPXMLParserExtensionElementType on generic FPXMLParser");
			break;
	}
}

// this method never seems to be called
- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
	if (self.currentElementType == FPXMLParserTextElementType) {
		[self.currentTextValue appendString:whitespaceString];
	}
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	switch (self.currentElementType) {
		case FPXMLParserTextElementType: {
			NSString *str = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
			if (str == nil) {
				// the data isn't valid UTF-8
				// try as ISO-Latin-1. Probably not correct, but at least it will never fail
				str = [[NSString alloc] initWithData:CDATABlock encoding:NSISOLatin1StringEncoding];
			}
			[self.currentTextValue appendString:str];
			break;
		}
		case FPXMLParserStreamElementType:
			[self abortParsing:parser withFormat:@"Unexpected CDATA at line %d", [parser lineNumber]];
			break;
		case FPXMLParserSkipElementType:
            break;
        case FPXMLParserExtensionElementType:
        case FPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FPXMLParserExtensionElementType on generic FPXMLParser");
			break;
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if (self.baseNamespaceURI == nil) {
		self.baseNamespaceURI = namespaceURI;
	}
	switch (self.currentElementType) {
		case FPXMLParserTextElementType:
			[self abortParsing:parser];
			break;
		case FPXMLParserStreamElementType: {
			FPXMLPair *keyPair = [FPXMLPair pairWithFirst:elementName second:namespaceURI];
			FPXMLPair *handler = [self.handlers objectForKey:keyPair];
			if (handler != nil) {
				SEL selector = NSSelectorFromString((NSString *)handler.first);
				self.currentElementType = (FPXMLParserElementType)[(NSNumber *)handler.second intValue];
				switch (self.currentElementType) {
					case FPXMLParserStreamElementType:
						if (selector != NULL) {
							handleStreamElement(self, selector, attributeDict, parser);
						}
						if ([parser delegate] == self) self.parseDepth++;
						break;
					case FPXMLParserTextElementType:
						self.currentTextValue = [[NSMutableString alloc] init];
						self.currentAttributeDict = attributeDict;
						self.currentHandlerSelector = selector;
						break;
					case FPXMLParserSkipElementType:
						if (selector != NULL) {
							handleSkipElement(self, selector, attributeDict, parser);
						}
						if ([parser delegate] == self) {
							self.skipDepth++;
						} else {
							// if the skip handler changed the delegate, then when we gain control
							// again we should be in the stream mode.
							// note that this is an exceptional condition, as skip handlers are not expected
							// to change the delegate. If the handler wants to do that it should use a stream handler.
							self.currentElementType = FPXMLParserStreamElementType;
						}
						break;
					case FPXMLParserExtensionElementType:
					case FPXMLParserTextExtensionElementType:
						;
						self.currentHandlerSelector = selector;
						FPExtensionElementNode *node = [[FPExtensionElementNode alloc] initWithElementName:elementName
																							  namespaceURI:namespaceURI
																							 qualifiedName:qualifiedName
																								attributes:attributeDict];
						[node acceptParsing:parser];
						[self.mutableExtensionElements addObject:node];
						break;
				}
			} else if ([namespaceURI isEqualToString:self.baseNamespaceURI]) {
				[self abortParsing:parser];
			} else if (![namespaceURI isEqualToString:kFPXMLParserAtomNamespaceURI] && ![namespaceURI isEqualToString:@""]) {
				// element is unknown and belongs to neither the Atom nor RSS namespaces
				FPExtensionElementNode *node = [[FPExtensionElementNode alloc] initWithElementName:elementName namespaceURI:namespaceURI
																					 qualifiedName:qualifiedName attributes:attributeDict];
				[node acceptParsing:parser];
				[self.mutableExtensionElements addObject:node];
			} else {
				// this is an unknown element outside of the base namespace, but still belonging to either RSS or Atom
				// As this is not in our base namespace, we are not required to handle it.
				// Do not use the extension mechanism for this because of forward-compatibility issues. If we use the
				// extension mechanism, then later add support for the element, code relying on the extension mechanism
				// would stop working.
				self.currentElementType = FPXMLParserSkipElementType;
				self.skipDepth = 1;
			}
			break;
		}
		case FPXMLParserSkipElementType:
			self.skipDepth++;
			break;
		case FPXMLParserExtensionElementType:
		case FPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FPXMLParserExtensionElementType on generic FPXMLParser");
			break;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	switch (self.currentElementType) {
		case FPXMLParserTextElementType: {
			if (self.currentHandlerSelector != NULL) {
				handleTextValue(self, self.currentHandlerSelector, self.currentTextValue, self.currentAttributeDict, parser);
			}
			self.currentHandlerSelector = NULL;
			self.currentTextValue = nil;
			self.currentAttributeDict = nil;
			self.currentElementType = FPXMLParserStreamElementType;
			break;
		}
		case FPXMLParserStreamElementType:
			self.parseDepth--;
			if (self.parseDepth == 0) {
				[self abdicateParsing:parser];
			}
			break;
		case FPXMLParserSkipElementType:
			self.skipDepth--;
			if (self.skipDepth == 0) {
				self.currentElementType = FPXMLParserStreamElementType;
			}
			break;
        case FPXMLParserExtensionElementType:
        case FPXMLParserTextExtensionElementType:
			// we should never parse an element while in this type
			NSAssert(NO, @"Encountered FPXMLParserExtensionElementType on generic FPXMLParser");
            break;
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[self abortParsing:parser];
}

#pragma mark FPXMLParserProtocol methods

- (void)acceptParsing:(NSXMLParser *)parser {
	self.parentParser = (id<FPXMLParserProtocol>)[parser delegate];
	[parser setDelegate:self];
}

- (void)abortParsing:(NSXMLParser *)parser {
	[self abortParsing:parser withString:nil];
}

- (void)resumeParsing:(NSXMLParser *)parser fromChild:(id<FPXMLParserProtocol>)child {
	if (self.currentElementType == FPXMLParserExtensionElementType ||
		self.currentElementType == FPXMLParserTextExtensionElementType) {
		NSAssert([child isKindOfClass:[FPExtensionNode class]], @"resumeParsing: called with unexpected child");
		FPExtensionNode *node = (FPExtensionNode *)child;
		if (self.currentElementType == FPXMLParserTextExtensionElementType) {
			// validation
			if ([node.children count] > 1 || ([node.children count] == 1 && ![[node.children objectAtIndex:0] isTextNode])) {
				[self abortParsing:parser withFormat:@"Unexpected child elements in node <%@>", node.qualifiedName];
				return;
			}
			if (self.currentHandlerSelector != NULL) {
				handleTextValue(self, self.currentHandlerSelector, node.stringValue, node.attributes, parser);
			}
		} else {
			if (self.currentHandlerSelector != NULL) {
				handleExtensionElement(self, self.currentHandlerSelector, node, parser);
			}
		}
		self.currentHandlerSelector = NULL;
		self.currentElementType = FPXMLParserStreamElementType;
	}
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [self init]) {
		self.baseNamespaceURI	= [aDecoder decodeObjectForKey:@"baseNamespaceURI"];
		self.extensionElements	= [aDecoder decodeObjectForKey:@"extensionElements"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.baseNamespaceURI forKey:@"baseNamespaceURI"];
	[aCoder encodeObject:self.extensionElements forKey:@"extensionElements"];
}
@end
