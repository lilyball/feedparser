//
//  FPExtensionElementNode.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/9/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPExtensionNode.h"

@protocol FPXMLParserProtocol;

// FPExtensionElementNode is used for unknown elements outside of the RSS and Atom namespaces
@interface FPExtensionElementNode : FPExtensionNode {
@private
	NSString *name;
	NSString *namespaceURI;
	NSDictionary *attributes;
	NSMutableArray *children;
	// parsing ivars
	id<FPXMLParserProtocol> parentParser;
	NSMutableString *currentText;
}
- (id)initWithElementName:(NSString *)name namespaceURI:(NSString *)namespaceURI attributes:(NSDictionary *)attributeDict;
@end
