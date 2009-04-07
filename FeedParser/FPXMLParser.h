//
//  FPXMLParser.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	FPXMLParserTextElementType = 1,
	FPXMLParserStreamElementType = 2
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
	SEL currentHandlerSelector;
}
+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FPXMLParserElementType)type;
- (id)initWithParent:(FPXMLParser *)parent;
- (void)abortParsing:(NSXMLParser *)parser;
- (void)abdicateParsing:(NSXMLParser *)parser;
@end
