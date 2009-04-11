//
//  NSString_extensions.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/10/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "NSString_extensions.h"

@implementation NSString (NSString_FeedParserExtensions)
- (NSString *)fpEscapedString {
	NSMutableString *escapedString = [NSMutableString stringWithCapacity:[self length]];
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	NSMutableCharacterSet *escapeSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"\"\\\n\r\t"];
	[escapeSet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
	while (![scanner isAtEnd]) {
		NSString *temp;
		if ([scanner scanUpToCharactersFromSet:escapeSet intoString:&temp]) {
			[escapedString appendString:temp];
		}
		if ([scanner scanCharactersFromSet:escapeSet intoString:&temp]) {
			for (NSUInteger idx = 0; idx < [temp length]; idx++) {
				unichar c = [temp characterAtIndex:idx];
				NSString *token;
				switch (c) {
					case '"':
						token = @"\\\"";
						break;
					case '\\':
						token = @"\\\\";
						break;
					case '\n':
						token = @"\\n";
						break;
					case '\r':
						token = @"\\r";
						break;
					case '\t':
						token = @"\\t";
						break;
					default:
						token = [NSString stringWithFormat:@"%C", c];
				}
				[escapedString appendString:token];
			}
		}
	}
	return escapedString;
}
@end
