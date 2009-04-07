//
//  RFC822Test.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "RFC822Test.h"
#import "NSDate_FeedParserExtensions.h"

@implementation RFC822Test
- (void)testDateWithRFC822 {
	STAssertEquals([[NSDate dateWithRFC822:@"Tue, 10 Jun 03 09:41:01 GMT"] timeIntervalSince1970], 1055238061.0, nil);
}

// this should be fleshed out to test all the edge cases
@end
