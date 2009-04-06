/*
 *  FPFeed_private.h
 *  FeedParser
 *
 *  Created by Kevin Ballard on 4/4/09.
 *  Copyright 2009 Kevin Ballard. All rights reserved.
 *
 */

#import "FPFeed.h"

typedef enum {
	FPFeedTypeRSS = 1,
	FPFeedTypeAtom = 2
} FPFeedType;

@class FPParser;

@interface FPFeed (Private)
- (id)initWithFeedType:(FPFeedType)type parser:(FPParser *)parser;
@end
