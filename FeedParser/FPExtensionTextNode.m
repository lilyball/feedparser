//
//  FPExtensionTextNode.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/9/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPExtensionTextNode.h"
#import "NSString_extensions.h"

@implementation FPExtensionTextNode
- (id)initWithStringValue:(NSString *)value {
	if (self = [super init]) {
		stringValue = [value copy];
	}
	return self;
}

- (BOOL)isTextNode {
	return YES;
}

- (NSString *)stringValue {
	return stringValue;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %0p \"%@\"", NSStringFromClass([self class]), self, [stringValue fpEscapedString]];
}

- (void)dealloc {
	[stringValue release];
	[super dealloc];
}
@end
