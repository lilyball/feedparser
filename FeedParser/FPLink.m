//
//  FPLink.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/10/09.
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

#import "FPLink.h"
#import "NSString_extensions.h"

@interface FPLink ()

@property (readwrite, copy, nonatomic) NSString *href;
@property (readwrite, copy, nonatomic) NSString *rel;
@property (readwrite, copy, nonatomic) NSString *type;
@property (readwrite, copy, nonatomic) NSString *title;

@end

@implementation FPLink

+ (id)linkWithHref:(NSString *)href rel:(NSString *)rel type:(NSString *)type title:(NSString *)title {
	return [[self alloc] initWithHref:href rel:rel type:type title:title];
}

- (id)initWithHref:(NSString *)href rel:(NSString *)rel type:(NSString *)type title:(NSString *)title {
	if (self = [super init]) {
		self.href	= href;
		self.rel	= (rel) ? rel : @"alternate";
		self.type	= type;
		self.title	= title;
	}
	return self;
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPLink class]]) {
		return NO;
	}
	FPLink *other = (FPLink *)anObject;
	return ((self.href == other.href || [self.href isEqualToString:other.href]) &&
			(self.rel == other.rel || [self.rel isEqualToString:other.rel]) &&
			(self.type == other.type || [self.type isEqualToString:other.type]) &&
			(self.title == other.title || [self.title isEqualToString:other.title]));
}

- (NSString *)description {
	NSMutableArray *attributes = [NSMutableArray array];
	for (NSString *key in [NSArray arrayWithObjects:@"rel", @"type", @"title", nil]) {
		NSString *value = [self valueForKey:key];
		if (value != nil) {
			[attributes addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, [value fpEscapedString]]];
		}
	}
	return [NSString stringWithFormat:@"<%@: %@ (%@)>", NSStringFromClass([self class]), self.href, [attributes componentsJoinedByString:@" "]];
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.href	= [aDecoder decodeObjectForKey:@"href"];
		self.rel	= [aDecoder decodeObjectForKey:@"rel"];
		self.type	= [aDecoder decodeObjectForKey:@"type"];
		self.title	= [aDecoder decodeObjectForKey:@"title"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.href	forKey:@"href"];
	[aCoder encodeObject:self.rel	forKey:@"rel"];
	[aCoder encodeObject:self.type	forKey:@"type"];
	[aCoder encodeObject:self.title	forKey:@"title"];
}

#pragma mark -
#pragma mark Copying Support

- (id)copyWithZone:(NSZone *)zone {
	return [[[self class] allocWithZone:zone] initWithHref:self.href rel:self.rel type:self.type title:self.title];
}

@end
