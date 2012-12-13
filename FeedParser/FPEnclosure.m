//
//  FPEnclosure.m
//  FeedParser
//
//  Created by Kevin Ballard on 11/20/09.
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

#import "FPEnclosure.h"

@interface FPEnclosure ()

@property (readwrite, copy,   nonatomic) NSString *url;
@property (readwrite, assign, nonatomic) NSUInteger length;
@property (readwrite, copy,   nonatomic) NSString *type;

@end

@implementation FPEnclosure

+ (id)enclosureWithURL:(NSString *)url length:(NSUInteger)length type:(NSString *)type {
	return [[self alloc] initWithURL:url length:length type:type];
}

- (id)initWithURL:(NSString *)url length:(NSUInteger)length type:(NSString *)type {
	if (self = [super init]) {
		self.url = url;
		self.length = length;
		self.type = type;
	}
	return self;
}

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[FPEnclosure class]]) {
		return NO;
	}
	FPEnclosure *other = (FPEnclosure *)object;
	return ((self.url == other.url || [self.url isEqualToString:other.url]) &&
			(self.type == other.type || [self.type isEqualToString:other.type]) &&
			(self.length == other.length));
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %@ (length=%lu type=\"%@\")>", NSStringFromClass([self class]), self.url, (unsigned long)self.length, self.type];
}

#pragma mark -
#pragma mark Coding Support

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.url	= [aDecoder decodeObjectForKey:@"url"];
		self.length	= [[aDecoder decodeObjectForKey:@"length"] unsignedIntegerValue];
		self.type	= [aDecoder decodeObjectForKey:@"type"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.url	forKey:@"url"];
	[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.length] forKey:@"length"];
	[aCoder encodeObject:self.type	forKey:@"type"];
}
@end
