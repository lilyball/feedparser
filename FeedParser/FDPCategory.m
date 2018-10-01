//
//  FDPCategory.m
//  FeedParser
//
//  Created by Kevin Ballard on 2/28/13.
//  Copyright 2013 Kevin Ballard. All rights reserved.
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

#import "FDPCategory.h"

@implementation FDPCategory
@synthesize domain=_domain, value=_value;
+ (instancetype)categoryWithDomain:(NSString *)domain value:(NSString *)value {
    return [[[self alloc] initWithDomain:domain value:value] autorelease];
}

- (id)initWithDomain:(NSString *)domain value:(NSString *)value {
    if ((self = [super init])) {
        _domain = [domain copy];
        _value = [value copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[FDPCategory class]]) return NO;
	FDPCategory *other = (FDPCategory *)object;
	return ((_domain    == other->_domain  || [_domain  isEqualToString:other->_domain]) &&
			(_value   == other->_value || [_value isEqualToString:other->_value]));
}

- (NSString *)description {
    if (self.domain) {
        return [NSString stringWithFormat:@"<%@: %@ (domain=\"%@\")>", NSStringFromClass([self class]), self.value, self.domain];
    } else {
        return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), self.value];
    }
}

- (void)dealloc {
    [_domain release];
    [_value release];
    [super dealloc];
}

#pragma mark -
#pragma mark Coding Support

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        _domain = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"domain"] copy];
        _value = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"value"] copy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_domain forKey:@"domain"];
    [aCoder encodeObject:_value forKey:@"value"];
}
@end
