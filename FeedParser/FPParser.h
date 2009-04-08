//
//  FPParser.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPXMLParser.h"

@class FPFeed;

@interface FPParser : FPXMLParser {
@private
	FPFeed *feed;
	NSString *errorString;
	BOOL lookingForChannel;
}
+ (FPFeed *)parsedFeedWithData:(NSData *)data error:(NSError **)error;
@end
