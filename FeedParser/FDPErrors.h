//
//  FDPErrors.h
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
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

#import <Foundation/Foundation.h>

extern NSString * const FDPParserErrorDomain;
extern NSString * const FPParserErrorDomain __attribute__((deprecated("replaced by FPParserErrorDomain", "FDPParserErrorDomain")));

typedef NS_ERROR_ENUM(FDPParserErrorDomain, FDPParserError) {
	FDPParserInternalError NS_SWIFT_NAME(internal) = 1,
	FDPParserInvalidFeedError NS_SWIFT_NAME(invalidFeed) = 2,
    
    FPParserInternalError __attribute__((deprecated("replaced by FDPParserInternalError", "FDPParserInternalError"))) NS_SWIFT_UNAVAILABLE("Use .internal") = FDPParserInternalError,
    FPParserInvalidFeedError __attribute__((deprecated("replaced by FDPParserInvalidFeedError", "FDPParserInvalidFeedError"))) NS_SWIFT_UNAVAILABLE("Use .invalidFeed") = FDPParserInvalidFeedError
};

typedef FDPParserError FPParserError __attribute__((deprecated("replaced by FDPParserError", "FDPParserError")));
