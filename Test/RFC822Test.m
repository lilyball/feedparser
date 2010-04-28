//
//  RFC822Test.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "RFC822Test.h"
#import "NSDate_FeedParserExtensions.h"

@implementation RFC822Test
- (void)testDateWithRFC822 {
	STAssertEquals([[NSDate dateWithRFC822:@"Tue, 10 Jun 03 09:41:01 GMT"] timeIntervalSince1970], 1055238061.0, nil);
	STAssertEquals([[NSDate dateWithRFC822:@"Tue, 10 Jun 03 07:41:01 B"] timeIntervalSince1970], 1055238061.0, nil);
	STAssertEquals([[NSDate dateWithRFC822:@"Tue, 10 Jun 03 07:41:01 -0200"] timeIntervalSince1970], 1055238061.0, nil);
	STAssertEquals([[NSDate dateWithRFC822:@"Tue, 10 Jun 03 11:51:01 +0210"] timeIntervalSince1970], 1055238061.0, nil);
	STAssertEquals([[NSDate dateWithRFC822:@"Fri, 15 Jan 2010 16:17:03"] timeIntervalSince1970], 1263572223.0, nil);
	// the following timestamp is a weird variant used by Google News
	STAssertEquals([[NSDate dateWithRFC822:@"Tue, 27 Apr 2010 23:08:21 GMT+00:00"] timeIntervalSince1970], 1272409701.0, nil);
}

// this should be fleshed out to test all the edge cases
@end
