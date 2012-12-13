//
//  FPExtensionElementNode.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/9/09.
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

#import "FPExtensionElementNode.h"
#import "FPExtensionNode_Private.h"
#import "FPExtensionElementNode_Private.h"
#import "FPXMLParserProtocol.h"
#import "FPExtensionTextNode.h"

@interface FPExtensionElementNode ()

@property (readwrite, unsafe_unretained, nonatomic) id<FPXMLParserProtocol> parentParser;
@property (readwrite, strong, nonatomic) NSMutableString *currentText;

- (void)closeTextNode;

@end

@implementation FPExtensionElementNode

- (id)initWithElementName:(NSString *)aName namespaceURI:(NSString *)aNamespaceURI qualifiedName:(NSString *)qName
			   attributes:(NSDictionary *)attributeDict {
	if (self = [super init]) {
		self.name = aName;
		self.qualifiedName = qName;
		self.namespaceURI = aNamespaceURI;
		self.attributes = attributeDict;
		self.mutableChildren = [[NSMutableArray alloc] init];
	}
	return self;
}

- (BOOL)isElement {
	return YES;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p <%@>>", NSStringFromClass([self class]), self, self.qualifiedName];
}

- (NSString *)stringValue {
	if ([self.mutableChildren count] == 1) {
		// optimize for single child
		return [[self.mutableChildren objectAtIndex:0] stringValue];
	} else {
		NSMutableString *stringValue = [NSMutableString string];
		for (FPExtensionNode *child in self.mutableChildren) {
			NSString *str = child.stringValue;
			if (str != nil) {
				[stringValue appendString:str];
			}
		}
		return stringValue;
	}
}

- (void)closeTextNode {
	FPExtensionTextNode *child = [[FPExtensionTextNode alloc] initWithStringValue:self.currentText];
	[self.mutableChildren addObject:child];
	self.currentText = nil;
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPExtensionElementNode class]]) return NO;
	FPExtensionElementNode *other = (FPExtensionElementNode *)anObject;
	return ((self.name == other.name || [self.name isEqualToString:other.name])           &&
			(self.qualifiedName == other.qualifiedName || [self.qualifiedName isEqualToString:other.qualifiedName])  &&
			(self.namespaceURI == other.namespaceURI || [self.namespaceURI isEqualToString:other.namespaceURI])   &&
			(self.attributes == other.attributes || [self.attributes isEqualToDictionary:other.attributes]) &&
			(self.children == other.children || [self.children isEqualToArray:other.children]));
}

#pragma mark XML parser methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)aNamespaceURI
 qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if (self.currentText != nil) {
		[self closeTextNode];
	}
	FPExtensionElementNode *child = [[FPExtensionElementNode alloc] initWithElementName:elementName namespaceURI:aNamespaceURI
																		  qualifiedName:qName attributes:attributeDict];
	[child acceptParsing:parser];
	[self.mutableChildren addObject:child];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if (self.currentText != nil) {
		[self closeTextNode];
	}
	[parser setDelegate:self.parentParser];
	[self.parentParser resumeParsing:parser fromChild:self];
	self.parentParser = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (self.currentText == nil) {
		self.currentText = [[NSMutableString alloc] init];
	}
	[self.currentText appendString:string];
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
	if (self.currentText == nil) {
		self.currentText = [[NSMutableString alloc] init];
	}
	[self.currentText appendString:whitespaceString];
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	NSString *data = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
	if (data == nil) {
		[self abortParsing:parser withString:[NSString stringWithFormat:@"Non-UTF8 data found in CDATA block at line %d", [parser lineNumber]]];
	} else {
		if (self.currentText == nil) {
			self.currentText = [[NSMutableString alloc] init];
		}
		[self.currentText appendString:data];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[self abortParsing:parser withString:nil];
}

#pragma mark FPXMLParserProtocol methods

- (void)acceptParsing:(NSXMLParser *)parser {
	self.parentParser = (id<FPXMLParserProtocol>)[parser delegate];
	[parser setDelegate:self];
}

- (void)abortParsing:(NSXMLParser *)parser withString:(NSString *)description {
	id<FPXMLParserProtocol> parent = self.parentParser;
	self.parentParser = nil;
	self.currentText = nil;
	[parent abortParsing:parser withString:description];
}

- (void)resumeParsing:(NSXMLParser *)parser fromChild:(id<FPXMLParserProtocol>)child {
	// stub
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.name			= [aDecoder decodeObjectForKey:@"name"];
		self.qualifiedName	= [aDecoder decodeObjectForKey:@"qualifiedName"];
		self.namespaceURI	= [aDecoder decodeObjectForKey:@"namespaceURI"];
		self.attributes		= [aDecoder decodeObjectForKey:@"attributes"];
		self.children		= [aDecoder decodeObjectForKey:@"children"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.name			forKey:@"name"];
	[aCoder encodeObject:self.qualifiedName	forKey:@"qualifiedName"];
	[aCoder encodeObject:self.namespaceURI	forKey:@"namespaceURI"];
	[aCoder encodeObject:self.attributes	forKey:@"attributes"];
	[aCoder encodeObject:self.children		forKey:@"children"];
}

@end
