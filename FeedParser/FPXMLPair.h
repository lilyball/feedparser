//
//  FPXMLPair.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// FPXLMPair is used to hold an immutable pair of objects
// useful for using as the key in a dictionary
@interface FPXMLPair : NSObject <NSCopying> {
	id first;
	id second;
}
@property (nonatomic, readonly) id first;
@property (nonatomic, readonly) id second;
+ (id)pairWithFirst:(id)firstObject second:(id)secondObject;
- (id)initWithFirst:(id)firstObject second:(id)secondObject;
@end
