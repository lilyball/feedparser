//
//  FPXMLParser.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	FPXMLParserTextElementType = 1,
	FPXMLParserStreamElementType = 2,
	FPXMLParserSkipElementType = 3 // for keys we're skipping, and don't care about the contents
} FPXMLParserElementType;

// RSS has no namespace, just test against @""
extern NSString * const kFPXMLParserAtomNamespaceURI;
extern NSString * const kFPXMLParserDublinCoreNamespaceURI;
extern NSString * const kFPXMLParserContentNamespaceURI;

@interface FPXMLParser : NSObject {
	FPXMLParser *parentParser; // non-retained
	NSDictionary *handlers;
	NSMutableString *currentTextValue;
	NSDictionary *currentAttributeDict;
	FPXMLParserElementType currentElementType;
	NSUInteger skipDepth;
	NSUInteger parseDepth;
	SEL currentHandlerSelector;
}
+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FPXMLParserElementType)type;
- (id)initWithParser:(NSXMLParser *)parser;
- (void)abortParsing:(NSXMLParser *)parser;
- (void)abortParsing:(NSXMLParser *)parser withFormat:(NSString *)description, ...;
- (void)abortParsing:(NSXMLParser *)parser withString:(NSString *)description;
- (void)abdicateParsing:(NSXMLParser *)parser;
@end
