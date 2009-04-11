//
//  FPExtensionTextNode.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/9/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPExtensionNode.h"

@interface FPExtensionTextNode : FPExtensionNode {
	NSString *stringValue;
}
- (id)initWithStringValue:(NSString *)value;
@end
