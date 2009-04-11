//
//  FPItem.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPXMLParser.h"

@class FPLink;

@interface FPItem : FPXMLParser {
@private
	NSString *title;
	FPLink *link;
	NSMutableArray *links;
	NSString *guid;
	NSString *content;
	NSDate *pubDate;
	NSString *creator; // <dc:creator>
}
@property (nonatomic, copy, readonly) NSString *title;
// RSS <link> or Atom <link rel="alternate">
// If multiple qualifying links exist, returns the first
@property (nonatomic, copy, readonly) FPLink *link;
// An array of FPLink objects corresponding to Atom <link> elements
// RSS <link> elements are treated as Atom <link rel="alternate"> elements
@property (nonatomic, copy, readonly) NSArray *links;
@property (nonatomic, copy, readonly) NSString *guid;
@property (nonatomic, copy, readonly) NSString *content;
@property (nonatomic, copy, readonly) NSString *creator; // <dc:creator>
@property (nonatomic, copy, readonly) NSDate *pubDate;
// parent class defines property NSArray *extensionElements
// parent class defines method - (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI
// parent class defines method - (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI elementName:(NSString *)elementName
@end
