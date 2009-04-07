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

@protocol FPParserDelegate;

@interface FPParser : FPXMLParser {
@private
	NSURLConnection *urlConnection;
	NSMutableData *networkData;
	FPFeed *feed;
	NSString *errorString;
	BOOL lookingForChannel;
}
+ (FPFeed *)parsedFeedWithData:(NSData *)data error:(NSError **)error;
+ (FPParser *)parserWithURL:(NSURL *)url delegate:(id<FPParserDelegate>)delegate;

- (id)initWithURL:(NSURL *)url delegate:(id<FPParserDelegate>)delegate;
// parse returns YES if the connection was initialized, NO otherwise
// the connection is scheduled using NSRunLoopCommonModes
- (BOOL)parse;
- (void)cancel; // cancels the feed download
@end

@protocol FPParserDelegate <NSObject>
@required
- (void)parser:(FPParser *)parser didParseFeed:(FPFeed *)feed;
- (void)parser:(FPParser *)parser didFailWithError:(NSError *)error;
@end
