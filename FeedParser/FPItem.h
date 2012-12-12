//
//  FPItem.h
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

@class FPLink;

@interface FPItem : FPXMLParser <NSCoding>

@property (readonly, copy, nonatomic) NSString *title;

// RSS <link> or Atom <link rel="alternate">
// If multiple qualifying links exist, returns the first
@property (readonly, strong, nonatomic) FPLink *link;

// An array of FPLink objects corresponding to Atom <link> elements
// RSS <link> elements are treated as Atom <link rel="alternate"> elements
@property (readonly, copy, nonatomic) NSArray *links;

@property (readonly, copy, nonatomic) NSString *guid;

@property (readonly, copy, nonatomic) NSString *description;

// The content property is, in most feeds, the same thing as the description property.
// However, if a feed contains a <content:encoded> tag, the content property will
// contain that data instead. The description tag will always contain the <description> tag.
// If you need to test for the presence of <content:encoded>, you can check if item.content == item.description.
@property (readonly, copy, nonatomic) NSString *content;

@property (readonly, copy, nonatomic) NSString *creator; // <dc:creator>

@property (readonly, copy, nonatomic) NSDate *pubDate;

@property (readonly, copy, nonatomic) NSString *author;

@property (readonly, copy, nonatomic) NSArray *enclosures;

// parent class defines property NSArray *extensionElements
// parent class defines method - (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI
// parent class defines method - (NSArray *)extensionElementsWithXMLNamespace:(NSString *)namespaceURI elementName:(NSString *)elementName

@end
