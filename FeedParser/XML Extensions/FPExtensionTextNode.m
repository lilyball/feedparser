//
//  FPExtensionTextNode.m
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

#import "FPExtensionTextNode.h"
#import "FPExtensionNode_Private.h"
#import "NSString_extensions.h"

@implementation FPExtensionTextNode

- (id)initWithStringValue:(NSString *)value {
	if (self = [super init]) {
		self.stringValue = value;
	}
	return self;
}

- (BOOL)isTextNode {
	return YES;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p \"%@\"", NSStringFromClass([self class]), self, [self.stringValue fpEscapedString]];
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPExtensionTextNode class]]) return NO;
	FPExtensionTextNode *other = (FPExtensionTextNode *)anObject;
	return (self.stringValue == other.stringValue || [self.stringValue isEqualToString:other.stringValue]);
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.stringValue = [aDecoder decodeObjectForKey:@"stringValue"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.stringValue forKey:@"stringValue"];
}
@end
