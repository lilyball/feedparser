//
//  FPFeed.h
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
#import "FPXMLParser.h"

@class FPParser;
@class FPLink;

@interface FPFeed : FPXMLParser <NSCoding>

@property (readonly, copy, nonatomic) NSString *title;

// RSS <link> or Atom <link rel="alternate">
// If multiple qualifying links exist, the first is returned
@property (readonly, copy, nonatomic) FPLink *link;

// An array of FPLink objects corresponding to Atom <link> elements
// RSS <link> elements are represented as links of rel="alternate"
@property (readonly, copy, nonatomic) NSArray *links;

@property (readonly, copy, nonatomic) NSString *feedDescription;

@property (readonly, copy, nonatomic) NSDate *pubDate;

@property (readonly, copy, nonatomic) NSArray *items;

// parent class defines property NSArray *extensionElements
// parent class defines method -(NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI
// parent class defines method - (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI elementName:(NSString *)elementName

@end
