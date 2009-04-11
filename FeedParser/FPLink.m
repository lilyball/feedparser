//
//  FPLink.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/10/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPLink.h"
#import "NSString_extensions.h"

@implementation FPLink
@synthesize href, rel, type, title;
- (id)initWithHref:(NSString *)inHref rel:(NSString *)inRel type:(NSString *)inType title:(NSString *)inTitle {
	if (self = [super init]) {
		href = [inHref copy];
		rel = (inRel ? [inRel copy] : @"alternate");
		type = [inType copy];
		title = [inTitle copy];
	}
	return self;
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[FPLink class]]) return NO;
	FPLink *other = (FPLink *)anObject;
	return ((href  == other.href  || [href  isEqualToString:other.href]) &&
			(rel   == other.rel   || [rel   isEqualToString:other.rel])  &&
			(type  == other.type  || [type  isEqualToString:other.type]) &&
			(title == other.title || [title isEqualToString:other.title]));
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

- (void)dealloc {
	[href release];
	[rel release];
	[type release];
	[title release];
	[super dealloc];
}

@end
