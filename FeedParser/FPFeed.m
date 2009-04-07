//
//  FPFeed.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPFeed.h"
#import "FPParser.h"
#import "NSDate_FeedParserExtensions.h"

@interface FPFeed ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *link;
@property (nonatomic, copy, readwrite) NSString *description;
@end

@implementation FPFeed
@synthesize title, link, description, pubDate;

+ (void)initialize {
	if (self == [FPFeed class]) {
		[self registerHandler:@selector(setTitle:) forElement:@"title" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setLink:) forElement:@"link" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setDescription:) forElement:@"description" namespaceURI:@"" type:FPXMLParserTextElementType];
		[self registerHandler:@selector(setPubDateString:attributes:parser:) forElement:@"pubDate" namespaceURI:@"" type:FPXMLParserTextElementType];
	}
}

- (void)setPubDateString:(NSString *)pubDateString attributes:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	[pubDate release];
	pubDate = [[NSDate dateWithRFC822:pubDateString] copy];
	if (pubDate == nil) [self abortParsing:parser];
}

- (void)dealloc {
	[title release];
	[link release];
	[description release];
	[pubDate release];
	[super dealloc];
}
@end
