//
//  FPFeed.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPXMLParser.h"

@class FPParser;

@interface FPFeed : FPXMLParser {
@private
	NSString *title;
	NSString *link;
	NSString *description;
	NSDate *pubDate;
}
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *link;
@property (nonatomic, copy, readonly) NSString *description;
@property (nonatomic, copy, readonly) NSDate *pubDate;
@end
