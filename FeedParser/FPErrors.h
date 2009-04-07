/*
 *  FPErrors.h
 *  FeedParser
 *
 *  Created by Kevin Ballard on 4/4/09.
 *  Copyright 2009 Kevin Ballard. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

extern NSString * const FPParserErrorDomain;

typedef enum {
	FPParserInternalError = 1,
	FPParserInvalidFeedError = 2
} FPParserError;
