//
//  FPXMLPair.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPXMLPair.h"

@implementation FPXMLPair
@synthesize first, second;

+ (id)pairWithFirst:(id)firstObject second:(id)secondObject {
	return [[[self alloc] initWithFirst:firstObject second:secondObject] autorelease];
}

- (id)initWithFirst:(id)firstObject second:(id)secondObject {
	if (self = [super init]) {
		first = [firstObject retain];
		second = [secondObject retain];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	return [[FPXMLPair allocWithZone:zone] initWithFirst:first second:second];
}

- (BOOL)isEqual:(id)anObject {
	if ([anObject isKindOfClass:[FPXMLPair class]]) {
		FPXMLPair *other = (FPXMLPair *)anObject;
		id oFirst = other.first;
		id oSecond = other.second;
		// do pointer test first so we handle nil properly
		return ((first == oFirst || [first isEqual:other.first]) && (second == oSecond || [second isEqual:other.second]));
	}
	return NO;
}

- (NSUInteger)hash {
	// xor in a magic value so that way our hash != [nil hash] if both first == nil && second == nil
	return 0xABADBABE ^ [first hash] ^ [second hash];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p: (%@, %@)>", NSStringFromClass([self class]), self, self.first, self.second];
}

- (void)dealloc {
	[first release];
	[second release];
	[super dealloc];
}
@end
