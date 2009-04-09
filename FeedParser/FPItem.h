//
//  FPItem.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPXMLParser.h"

@interface FPItem : FPXMLParser {
	NSString *title;
	NSString *link;
	NSString *guid;
	NSString *content;
	NSDate *pubDate;
	NSString *creator; // <dc:creator>
}
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *link;
@property (nonatomic, copy, readonly) NSString *guid;
@property (nonatomic, copy, readonly) NSString *content;
@property (nonatomic, copy, readonly) NSString *creator; // <dc:creator>
@property (nonatomic, copy, readonly) NSDate *pubDate;
// parent class defines property NSArray *extensionElements
// parent class defines method -(NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI
@end
