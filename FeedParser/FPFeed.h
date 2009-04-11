//
//  FPFeed.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPXMLParser.h"

@class FPParser;
@class FPLink;

@interface FPFeed : FPXMLParser {
@private
	NSString *title;
	FPLink *link;
	NSMutableArray *links;
	NSString *feedDescription;
	NSDate *pubDate;
	NSMutableArray *items;
}
@property (nonatomic, copy, readonly) NSString *title;
// RSS <link> or Atom <link rel="alternate">
// If multiple qualifying links exist, the first is returned
@property (nonatomic, copy, readonly) FPLink *link;
// An array of FPLink objects corresponding to Atom <link> elements
// RSS <link> elements are represented as links of rel="alternate"
@property (nonatomic, copy, readonly) NSArray *links;
@property (nonatomic, copy, readonly) NSString *feedDescription;
@property (nonatomic, copy, readonly) NSDate *pubDate;
@property (nonatomic, retain, readonly) NSArray *items;
// parent class defines property NSArray *extensionElements
// parent class defines method -(NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI
@end
