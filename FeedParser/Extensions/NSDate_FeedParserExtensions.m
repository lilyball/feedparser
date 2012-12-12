//
//  NSDate_extensions.m
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

#import "NSDate_FeedParserExtensions.h"

static NSArray *kDays;
static NSArray *kMonths;

@implementation NSObject (NSDate_FeedParserExtensions)

+ (void)load {
	kDays = [[NSArray alloc] initWithObjects:@"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat", @"Sun", nil];
	kMonths = [[NSArray alloc] initWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil];
}

+ (NSDate *)dateWithRFC822:(NSString *)rfc822 {
	NSDate *date = nil;
	@autoreleasepool {
		NSDateComponents *components = [[NSDateComponents alloc] init];
		NSScanner *scanner = [NSScanner scannerWithString:rfc822];
		NSCharacterSet *letterSet;
		{
			NSMutableCharacterSet *cs = [NSMutableCharacterSet characterSetWithRange:NSMakeRange((NSUInteger)'a', 26)];
			[cs addCharactersInRange:NSMakeRange((NSUInteger)'A', 26)];
			letterSet = cs;
		}
		NSCharacterSet *digitSet = [NSCharacterSet characterSetWithRange:NSMakeRange((NSUInteger)'0', 10)];
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@" \t"]];
		NSString *temp;
		if ([scanner scanCharactersFromSet:letterSet intoString:&temp]) {
			if (![kDays containsObject:temp] || ![scanner scanString:@"," intoString:NULL]) {
				return nil;
			}
		}
		if (![scanner scanCharactersFromSet:digitSet intoString:&temp] || [temp length] < 1 || [temp length] > 2) {
			return nil;
		}
		[components setDay:[temp integerValue]];
		if (![scanner scanCharactersFromSet:letterSet intoString:&temp]) {
			return nil;
		}
		NSUInteger month = [kMonths indexOfObject:temp];
		if (month == NSNotFound) {
			return nil;
		}
		[components setMonth:(month+1)];
		if (![scanner scanCharactersFromSet:digitSet intoString:&temp] || ([temp length] != 2 && [temp length] != 4)) {
			return nil;
		}
		// Treat 2-digit years as (1969-2000) or (2001-2068)
		NSInteger year = [temp integerValue];
		if ([temp length] == 2) {
			year += (year >= 69 ? 1900 : 2000);
		}
		[components setYear:year];
		if (![scanner scanCharactersFromSet:digitSet intoString:&temp] || [temp length] != 2) {
			return nil;
		}
		[components setHour:[temp integerValue]];
		if (![scanner scanString:@":" intoString:NULL]) {
			return nil;
		}
		if (![scanner scanCharactersFromSet:digitSet intoString:&temp] || [temp length] != 2) {
			return nil;
		}
		[components setMinute:[temp integerValue]];
		if ([scanner scanString:@":" intoString:NULL]) {
			if (![scanner scanCharactersFromSet:digitSet intoString:&temp] || [temp length] != 2) {
				return nil;
			}
			[components setSecond:[temp integerValue]];
		}
		// Default to GMT, for feeds that have malformed dates and don't explicitly specify a timezone.
		NSTimeZone *tz = [NSTimeZone timeZoneForSecondsFromGMT:0];
		if ([scanner scanCharactersFromSet:letterSet intoString:&temp]) {
			tz = [NSTimeZone timeZoneWithAbbreviation:temp];
			if (tz == nil && [temp length] == 1) {
				unichar c = [temp characterAtIndex:0];
				if (c == 'Z') {
					tz = [NSTimeZone timeZoneForSecondsFromGMT:0];
				} else if (c >= 'A' && c < 'J') {
					// A = -1, I = -9, skip J
					tz = [NSTimeZone timeZoneForSecondsFromGMT:((-1 - (c - 'A')) * 3600)];
				} else if (c > 'J' && c <= 'M') {
					// K = -10, M = -12
					tz = [NSTimeZone timeZoneForSecondsFromGMT:((-10 - (c - 'K')) * 3600)];
				} else if (c >= 'N' && c <= 'Y') {
					// N = 1, Y = 12
					tz = [NSTimeZone timeZoneForSecondsFromGMT:((1 + (c - 'N')) * 3600)];
				}
			}
		}
		// some feeds (such as Google News) specify their time zone with both formats, e.g. GMT+00:00
		// when we encounter this format, trust the number over the letters
		// also note that this weird format uses +00:00 instead of +0000. Very weird, but let's support that too
		if ([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"-+"] intoString:&temp]) {
			BOOL neg = [temp isEqualToString:@"-"];
			if (![scanner scanCharactersFromSet:digitSet intoString:&temp] || ([temp length] != 2 && [temp length] != 4)) {
				return nil;
			}
			if ([temp length] == 2) {
				NSString *hours = temp;
				if (![scanner scanString:@":" intoString:NULL]) {
					return nil;
				}
				if (![scanner scanCharactersFromSet:digitSet intoString:&temp] || [temp length] != 2) {
					return nil;
				}
				temp = [hours stringByAppendingString:temp];
			}
			NSInteger hourOffset = [[temp substringToIndex:2] integerValue];
			NSInteger minuteOffset = [[temp substringFromIndex:2] integerValue];
			NSInteger offset = hourOffset * 3600 + minuteOffset * 60;
			if (neg) offset = -offset;
			tz = [NSTimeZone timeZoneForSecondsFromGMT:offset];
		}
		if (tz == nil) {
			return nil;
		}
		if (![scanner isAtEnd]) {
			return nil;
		}
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[calendar setTimeZone:tz];
		date = [calendar dateFromComponents:components];
	}
	return date;
}

@end
