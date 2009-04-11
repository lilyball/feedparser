//
//  FPExtensionNode.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/9/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>

// FPExtensionNode is used to represent extension elements outside of the RSS/Atom namespaces
// conceptually this is an extremely simplified NSXMLNode
// it can represent either textual data (FPExtensionTextNode) or an element (FPExtensionElementNode)
@interface FPExtensionNode : NSObject {
}
@property (nonatomic, readonly) BOOL isElement;
@property (nonatomic, readonly) BOOL isTextNode;

// stringValue returns a string representing the node
// for text nodes, it returns the text associated with the node
// for element nodes, it returns a concatenation of the stringValue of all its children
// this means that any child element nodes get effectively flattened out and disappear
@property (nonatomic, readonly) NSString *stringValue;

// The following properties are only valid for element nodes
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *qualifiedName; // returns the name as existed in the XML source
@property (nonatomic, readonly) NSString *namespaceURI;
@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, readonly) NSArray *children; // an array of FPExtensionNodes
@end
