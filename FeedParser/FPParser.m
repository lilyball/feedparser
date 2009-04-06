//
//  FPParser.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/4/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPParser.h"
#import "FPFeed.h"
#import "FPFeed_private.h"
#import "FPErrors.h"

NSString * const FPParserErrorDomain = @"FPParserErrorDomain";

@interface FPParser ()
- (FPFeed *)parseData:(NSData *)data error:(NSError **)error;
@end

@implementation FPParser
+ (FPFeed *)parsedFeedWithData:(NSData *)data error:(NSError **)error {
	FPParser *parser = [[[FPParser alloc] init] autorelease];
	return [parser parseData:data error:error];
}

+ (FPParser *)parserWithURL:(NSURL *)url delegate:(id<FPParserDelegate>)delegate {
	NSAssert(NO, @"Not yet implemented"); // TODO
	return nil;
}

- (id)initWithURL:(NSURL *)url delegate:(id<FPParserDelegate>)delegate {
	[self release];
	NSAssert(NO, @"Not yet implemented"); // TODO
	return nil;
}

- (BOOL)parse {
	NSAssert(NO, @"Not yet implemented"); // TODO
	return NO;
}

- (void)cancel {
	NSAssert(NO, @"Not yet implemented"); // TODO
}

- (void)dealloc {
	[urlConnection cancel];
	[urlConnection release];
	[networkData release];
	[feed release];
	[super dealloc];
}

#pragma mark -

- (FPFeed *)parseData:(NSData *)data error:(NSError **)error {
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	if (xmlParser == nil) {
		*error = [NSError errorWithDomain:FPParserErrorDomain code:FPParserInternalError userInfo:nil];
		return nil;
	}
	[xmlParser setDelegate:self];
	[xmlParser setShouldProcessNamespaces:YES];
	if ([xmlParser parse]) {
		FPFeed *retFeed = [feed autorelease];
		feed = nil;
		return retFeed;
	} else {
		[feed release]; feed = nil;
		*error = [xmlParser parserError];
		return nil;
	}
}

#pragma mark XML Parser methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	[feed release];
	feed = nil;
	lookingForChannel = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[parser abortParsing];
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	[parser abortParsing];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[parser abortParsing];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if (feed != nil) {
		[parser abortParsing];
	}
	if (!lookingForChannel && [namespaceURI isEqualToString:@"http://www.w3.org/2005/Atom"] && [elementName isEqualToString:@"feed"]) {
		feed = [[FPFeed alloc] initWithFeedType:FPFeedTypeAtom parser:self];
		[parser setDelegate:feed];
	} else if ([namespaceURI isEqualToString:@""]) {
		if (lookingForChannel && [elementName isEqualToString:@"channel"]) {
			feed = [[FPFeed alloc] initWithFeedType:FPFeedTypeRSS parser:self];
			[parser setDelegate:feed];
			lookingForChannel = NO;
		} else if (!lookingForChannel && [elementName isEqualToString:@"rss"]) {
			NSString *version = [attributeDict objectForKey:@"version"];
			if ([version isEqualToString:@"2.0"] || [version isEqualToString:@"0.92"] || [version isEqualToString:@"0.91"]) {
				lookingForChannel = YES;
			} else {
				[parser abortParsing];
			}
		} else {
			[parser abortParsing];
		}
	} else {
		[parser abortParsing];
	}
}
@end
