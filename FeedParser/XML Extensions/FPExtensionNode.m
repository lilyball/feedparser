//
//  FPExtensionNode.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/9/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPExtensionNode.h"
#import "FPExtensionElementNode.h"
#import "FPExtensionTextNode.h"

@implementation FPExtensionNode
- (BOOL)isElement {
	return NO;
}

- (BOOL)isTextNode {
	return NO;
}

- (NSString *)stringValue {
	return nil;
}

- (NSString *)name {
	return nil;
}

- (NSString *)qualifiedName {
	return nil;
}

- (NSString *)namespaceURI {
	return nil;
}

- (NSDictionary *)attributes {
	return nil;
}

- (NSArray *)children {
	return nil;
}
@end
