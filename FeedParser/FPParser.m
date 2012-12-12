//
//  FPParser.m
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

#import "FPParser.h"
#import "FPXMLParser_Private.h"
#import "FPFeed.h"
#import "FPErrors.h"

NSString * const FPParserErrorDomain = @"FPParserErrorDomain";

@interface FPParser ()

@property (readwrite, strong, nonatomic) FPFeed *feed;
@property (readwrite, copy,   nonatomic) NSString *errorString;
@property (readwrite, assign, nonatomic) BOOL lookingForChannel;

- (FPFeed *)parseData:(NSData *)data error:(NSError **)error;

@end

@implementation FPParser

+ (void)initialize {
	if (self == [FPParser class]) {
		[self registerRSSHandler:@selector(rss_rss:parser:) forElement:@"rss" type:FPXMLParserStreamElementType];
		[self registerRSSHandler:@selector(rss_channel:parser:) forElement:@"channel" type:FPXMLParserStreamElementType];
		[self registerAtomHandler:@selector(atom_feed:parser:) forElement:@"feed" type:FPXMLParserStreamElementType];
	}
}

+ (FPFeed *)parsedFeedWithData:(NSData *)data error:(NSError **)error {
	FPParser *parser = [[self alloc] init];
	return [parser parseData:data error:error];
}

#pragma mark -

- (FPFeed *)parseData:(NSData *)data error:(NSError **)error {
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	if (xmlParser == nil) {
		if (error) *error = [NSError errorWithDomain:FPParserErrorDomain code:FPParserInternalError userInfo:nil];
		return nil;
	}
	self.parseDepth = 1;
	[xmlParser setDelegate:self];
	[xmlParser setShouldProcessNamespaces:YES];
	if ([xmlParser parse]) {
		if (self.feed != nil) {
			FPFeed *retFeed = self.feed;
			self.feed = nil;
			self.errorString = nil;
			return retFeed;
		} else {
			// nil means we aborted, but NSXMLParser didn't record the error
			// there's a bug in NSXMLParser which means aborting in some cases produces no error value
			if (self.errorString == nil) {
				// no errorString means the parse actually succeeded, but didn't contain a feed
				self.errorString = @"The XML document did not contain a feed";
			}
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.errorString forKey:NSLocalizedDescriptionKey];
			self.errorString = nil;
			if (error) *error = [NSError errorWithDomain:FPParserErrorDomain code:FPParserInvalidFeedError userInfo:userInfo];
			return nil;
		}
	} else {
		self.feed = nil;
		if (error) {
			*error = [xmlParser parserError];
			if ([[*error domain] isEqualToString:NSXMLParserErrorDomain]) {
				if ([*error code] == NSXMLParserInternalError) {
					NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.errorString forKey:NSLocalizedDescriptionKey];
					*error = [NSError errorWithDomain:FPParserErrorDomain code:FPParserInternalError userInfo:userInfo];
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
		self.errorString = nil;
		return nil;
	}
}

- (void)abortParsing:(NSXMLParser *)parser withString:(NSString *)description {
	self.feed = nil;
	if (description == nil) {
		self.errorString = [[NSString alloc] initWithFormat:@"Invalid feed data at line %ld", (long)[parser lineNumber]];
	} else {
		self.errorString = [[NSString alloc] initWithFormat:@"Invalid feed data at line %ld: %@", (long)[parser lineNumber], description];
	}
	[super abortParsing:parser withString:description];
}

#pragma mark XML Parser methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	self.feed = nil;
	self.lookingForChannel = NO;
}

#pragma mark Element handlers

- (void)rss_rss:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	if (self.feed != nil || self.lookingForChannel) {
		[self abortParsing:parser];
	} else {
		NSString *version = [attributes objectForKey:@"version"];
		if ([version isEqualToString:@"2.0"] || [version isEqualToString:@"0.92"] || [version isEqualToString:@"0.91"]) {
			self.lookingForChannel = YES;
		} else {
			[self abortParsing:parser];
		}
	}
}

- (void)rss_channel:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	if (self.feed != nil || !self.lookingForChannel) {
		[self abortParsing:parser];
	} else {
		self.feed = [[FPFeed alloc] initWithBaseNamespaceURI:self.baseNamespaceURI];
		[self.feed acceptParsing:parser];
		self.lookingForChannel = NO;
	}
}

- (void)atom_feed:(NSDictionary *)attributes parser:(NSXMLParser *)parser {
	if (self.feed != nil || self.lookingForChannel) {
		[self abortParsing:parser];
	} else {
		self.feed = [[FPFeed alloc] initWithBaseNamespaceURI:self.baseNamespaceURI];
		[self.feed acceptParsing:parser];
	}
}
@end
