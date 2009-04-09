//
//  FPExtensionTextNode.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/9/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPExtensionTextNode.h"

@implementation FPExtensionTextNode
- (id)initWithStringValue:(NSString *)value {
	if (self = [super init]) {
		stringValue = [value copy];
	}
	return self;
}

- (BOOL)isTextNode {
	return YES;
}

- (NSString *)stringValue {
	return stringValue;
}

- (NSString *)description {
	NSMutableString *escapedString = [NSMutableString stringWithCapacity:[stringValue length]];
	NSScanner *scanner = [NSScanner scannerWithString:stringValue];
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
	return [NSString stringWithFormat:@"<%@: %0p \"%@\"", NSStringFromClass([self class]), self, escapedString];
}

- (void)dealloc {
	[stringValue release];
	[super dealloc];
}
@end
