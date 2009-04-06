//
//  FPFeed.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FPParser;

@interface FPFeed : NSObject {
@private
	FPParser *feedParser; // non-retained
	NSString *feedNamespace;
	NSString *title;
	NSString *link;
	NSString *description;
	NSDate *pubDate;
}
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *link;
@property (nonatomic, readonly) NSString *description;
@property (nonatomic, readonly) NSDate *pubDate;
@end
