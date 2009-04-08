//
//  NSDate_extensions.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (NSDate_FeedParserExtensions)
+ (NSDate *)dateWithRFC822:(NSString *)rfc822;
@end
