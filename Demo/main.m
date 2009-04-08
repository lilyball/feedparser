/*
 *  main.m
 *  FeedParser
 *
 *  Created by Kevin Ballard on 4/6/09.
 *  Copyright 2009 Kevin Ballard. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import "FeedParser.h"

int main() {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	// this sample RSS is just the first few fields of the sample-rss-2.rss file
	NSString *rss = @"\
<?xml version=\"1.0\"?>\
<rss version=\"2.0\">\
   <channel>\
      <title>Liftoff News</title>\
      <link>http://liftoff.msfc.nasa.gov/</link>\
      <description>Liftoff to Space Exploration.</description>\
	</channel>\
</rss>";
	NSData *data = [rss dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error;
	FPFeed *feed = [FPParser parsedFeedWithData:data error:&error];
	if (feed) {
		printf("feed: %s", [[feed description] UTF8String]);
	} else {
		printf("error: %s", [[error localizedDescription] UTF8String]);
	}
	[pool release];
}
