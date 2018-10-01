//
//  FDPParser.m
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

#import "FDPParser.h"
#import "FDPFeed.h"
#import "FDPErrors.h"

NSString * const FDPParserErrorDomain = @"FDPParserErrorDomain";
NSString * const FPParserErrorDomain = FDPParserErrorDomain;

@interface FDPParser ()
- (FDPFeed *)parseData:(NSData *)data error:(NSError **)error;
@end

@implementation FDPParser
+ (void)initialize {
	if (self == [FDPParser class]) {
		[self registerRSSHandler:@selector(rss_rss:parser:) forElement:@"rss" type:FDPXMLParserStreamElementType];
		[self registerRSSHandler:@selector(rss_channel:parser:) forElement:@"channel" type:FDPXMLParserStreamElementType];
		[self registerAtomHandler:@selector(atom_feed:parser:) forElement:@"feed" type:FDPXMLParserStreamElementType];
	}
}

+ (FDPFeed *)parsedFeedWithData:(NSData *)data error:(NSError **)error {
	FDPParser *parser = [[[FDPParser alloc] init] autorelease];
	return [parser parseData:data error:error];
}

- (void)dealloc {
	[feed release];
	[errorString release];
	[super dealloc];
}

#pragma mark -

- (FDPFeed *)parseData:(NSData *)data error:(NSError **)error {
	NSXMLParser *xmlParser = [[[NSXMLParser alloc] initWithData:data] autorelease];
	if (xmlParser == nil) {
        if (error) *error = [NSError errorWithDomain:FDPParserErrorDomain code:FDPParserErrorInternal userInfo:nil];
		return nil;
	}
	parseDepth = 1;
	[xmlParser setDelegate:self];
	[xmlParser setShouldProcessNamespaces:YES];
	if ([xmlParser parse]) {
		if (feed != nil) {
			FDPFeed *retFeed = [feed autorelease];
			feed = nil;
			[errorString release]; errorString = nil;
			return retFeed;
		} else {
			// nil means we aborted, but NSXMLParser didn't record the error
			// there's a bug in NSXMLParser which means aborting in some cases produces no error value
			if (errorString == nil) {
				// no errorString means the parse actually succeeded, but didn't contain a feed
				errorString = @"The XML document did not contain a feed";
			}
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
			[errorString release]; errorString = nil;
            if (error) *error = [NSError errorWithDomain:FDPParserErrorDomain code:FDPParserErrorInvalidFeed userInfo:userInfo];
			return nil;
		}
	} else {
		[feed release]; feed = nil;
		if (error) {
			*error = [xmlParser parserError];
			if ([[*error domain] isEqualToString:NSXMLParserErrorDomain]) {
				if ([*error code] == NSXMLParserInternalError) {
					NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:FDPParserErrorDomain code:FDPParserErrorInternal userInfo:userInfo];
				} else {
					// adjust the error localizedDescription to include the line/column numbers
					NSString *desc = [NSString stringWithFormat:@"line %ld, column %ld: %@",
									  (long)[xmlParser lineNumber],
									  (long)[xmlParser columnNumber],
									  [*error localizedDescription]];
					NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[*error userInfo]];
					[userInfo setObject:desc forKey:NSLocalizedDescriptionKey];
					*error = [NSError errorWithDomain:[*error domain] code:[*error code] userInfo:userInfo];
				}
			}
		}
		[errorString release]; errorString = nil;
		return nil;
	}
}

- (void)abortParsing:(NSXMLParser *)parser withString:(NSString *)description {
	[feed release];
	feed = nil;
	[errorString release];
	if (description == nil) {
		errorString = [[NSString alloc] initWithFormat:@"Invalid feed data at line %ld", (long)[parser lineNumber]];
	} else {
		errorString = [[NSString alloc] initWithFormat:@"Invalid feed data at line %ld: %@", (long)[parser lineNumber], description];
	}
	[super abortParsing:parser withString:description];
}

#pragma mark XML Parser methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	[feed release];
	feed = nil;
	lookingForChannel = NO;
}

#pragma mark Element handlers

- (void)rss_rss:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	if (feed != nil || lookingForChannel) {
		[self abortParsing:parser];
	} else {
		NSString *version = [attributes objectForKey:@"version"];
		if ([version isEqualToString:@"2.0"] || [version isEqualToString:@"0.92"] || [version isEqualToString:@"0.91"]) {
			lookingForChannel = YES;
		} else {
			[self abortParsing:parser];
		}
	}
}

- (void)rss_channel:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	if (feed != nil || !lookingForChannel) {
		[self abortParsing:parser];
	} else {
		feed = [[FDPFeed alloc] initWithBaseNamespaceURI:baseNamespaceURI];
		[feed acceptParsing:parser];
		lookingForChannel = NO;
	}
}

- (void)atom_feed:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	if (feed != nil || lookingForChannel) {
		[self abortParsing:parser];
	} else {
		feed = [[FDPFeed alloc] initWithBaseNamespaceURI:baseNamespaceURI];
		[feed acceptParsing:parser];
	}
}
@end
