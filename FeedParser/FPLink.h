//
//  FPLink.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/10/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FPLink : NSObject {
@private
	NSString *href;
	NSString *rel;
	NSString *type;
	NSString *title;
}
@property (nonatomic, readonly) NSString *href;
@property (nonatomic, readonly) NSString *rel; // the value of the rel attribute or @"alternate"
@property (nonatomic, readonly) NSString *type; // the value of the type attribute or nil
@property (nonatomic, readonly) NSString *title; // the value of the title attribute or nil
+ (id)linkWithHref:(NSString *)href rel:(NSString *)rel type:(NSString *)type title:(NSString *)title;
- (id)initWithHref:(NSString *)href rel:(NSString *)rel type:(NSString *)type title:(NSString *)title;
@end
