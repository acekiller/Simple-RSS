//
//  Experiment.m
//  Simple RSS
//
//  Created by Manh Tuan Cao on 11/05/2010.
//  Copyright 2010 University of Sunderland. All rights reserved.
//

#import "Experiment.h"
#import "EGODatabase.h"
#import "DB.h"
#import "EGODB.h"
#import "DateHelper.h"
#import "Group.h"
#import "RSSParser.h"
#import "MySingleton.h"
#import "ASIHTTPRequest.h"
#import "Three20/Three20.h"
#import "TBXML.h"
#import "GoogleReaderHelper.h"
#import "UserDefinedConst.h"

@implementation Experiment

+ (void) TestDatabase {
	NSLog(@"----------------------------Testing Database------------------------------");

	//NSString *path = [[NSBundle mainBundle] pathForResource:@"SimpleRSS" ofType:@"db"];
//	NSLog(@"The path is: %@", path);
//	EGODatabase *db = [[EGODatabase alloc] initWithPath:path];
//	NSString *query = [[NSString alloc] initWithString:@"insert into Feed ('FeedID', 'Title', 'UnreadCount') values ('12313','Test title', 3)"];
//	
//	
//	if ([db open]) {
//		
//		if ([db executeUpdate:query]) {
//			NSLog(@"Inserted Succesfully");
//		}else {
//			NSLog(@"Failed");
//		}
//
//		NSLog(@"The database is opened");
//		EGODatabaseResult* result = [db executeQuery:@"SELECT * FROM Feed"];
//		for(EGODatabaseRow* row in result) {
//			NSLog(@"Feed ID: %@", [row stringForColumn:@"FeedID"]);
//			NSLog(@"Title: %@", [row stringForColumn:@"Title"]);
//			NSLog(@"Oringinal URL: %d", [row stringForColumn:@"OriginalURL"]);
//			//NSLog(@"Message: %@", [row stringForColumn:@"post_message"]);
//		}
//	}
//	[db release];
	//EGODatabase* database = [EGODatabase databaseWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"SimpleRSS.db"]];
	
//	EGODB *newDB = [[EGODB alloc] init];
//	Feed *aFeed = [[Feed alloc] init];
//	[aFeed setFeedID:@"af232d3"];
//	[aFeed setTitle:@"Test Title"];
//	
//	[aFeed setOriginalURL:@"abc.com"];
//	[newDB addFeed:aFeed];
//	
//	[aFeed release];
//	NSArray *feedids =  [newDB getFeeds];
//	for (NSString *str in feedids) {
//		NSLog(@"%@",str);
//	}
//	[newDB release];

//	NSLog(@"Today is: %d", [DateHelper getTimeStampFromNDaysAgo:0]);
//	NSLog(@"Yesterday is: %d", [DateHelper getTimeStampFromNDaysAgo:1]);	

	
//	if ([db deleteFeedWithFeedID:@"feed/http://iphone.keyvisuals.com/feed/"]) {
//		NSLog(@"Deleted ");
//	}else {
//		NSLog(@"Failed to delete");
//	}
//
	
//	NSString *tesString = @"tag:google.com,2005:reader/item/d963a00fe280dd12";
//	NSString *searchString = @"/";
//	
//	NSRange position = [ tesString rangeOfString:searchString options:NSBackwardsSearch];
//	
//	NSString *rs = [tesString substringFromIndex:position.location +1 ];
//	
//	NSLog(@"Test String: %@ \n Results: %@",tesString, rs);
//
/*
	EGODB *db = [[EGODB alloc] init];	
	Group *aGroup = [db getGroupWithGroupID:@"user/15632046837878276347/label/Apple" title:@"Apple"];
	NSLog(@"Unread Count: %d",[aGroup unreadCount]);
	NSLog(@"Number of Feeds: %d",[[aGroup feedsDict] count]);
	for (NSString *aFeedID in [aGroup feedsDict]) {
		NSLog(@"FeedID : %@ Title: %@",aFeedID , [[[aGroup feedsDict] objectForKey:aFeedID] title]);
	}
	[db release];
*/
//	NSURL *tmpurl = [RSSParser getFaviconURL:@"feed/http://cssvault.com/gallery.xml"];
	
/*	EGODB *db = [[EGODB alloc] init];	
	Group *agroup = [db getFullGroupWithGroupID:@"user/15632046837878276347/label/Good Read"];
	
	for (Feed *aFeed in [agroup feedsList]) {
		NSLog(@"Feed Title: %@",[aFeed title]);
		for (NewsItem *aItem in [aFeed newsItems]) {
			NSLog(@"	News Title: %@",[aItem title]);
		}
	}
	
	[db release];
*/
/*	TTMarkupStripper *markup = [[TTMarkupStripper alloc] init];
	NSString *contentWithHTML = [NSString stringWithString:@"<img source='http://' >  </img> <p> THe main text <a></p>"];
	NSLog(@"Orginal Text : %@",contentWithHTML);
	NSLog(@"Parsed Text: %@", [markup parse:contentWithHTML]);

	
	[markup release];
 */

	
/*	NSString *googleSID = @"DQAAALAAAABjHpRCmy8KsbTPyiUrmf9sSqZOI30nHTuCG5qmARqTjzplTvuSotKFJa-ghpl0IdwRiKk7uLvWE2Fu7K6pQmWP7tGkZTGKd8sufhftFpU_jUYTFFfLW2-J6RdT5nN5MUGTDHlI1vR2auZJ2nAoSrtS7XvqG5hHip9EzYJO4A8ISprdEIKr_w8r4zJVWxaLkrV2slZZJ4esIU2X5sH_Q4rGtpkCechuYevOru-76hqa4Q";
	NSDictionary *properties = [[NSDictionary alloc] initWithObjectsAndKeys:@"SID",NSHTTPCookieName, googleSID,NSHTTPCookieValue,@".google.com",NSHTTPCookieDomain, @"/",NSHTTPCookiePath, nil];
	
	NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:properties];
//	if (cookie != nil ) {
//		NSLog(@"Created Cookies");
//	} else {
//		NSLog(@"Failed Creating cookies");
//	}
	ASIHTTPRequest *request;
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:kURLgetUnreadItemIDsFormat, 1275045129]]] autorelease];
	
	[GoogleReaderHelper getTokenID:googleSID];
	//NSString *cookie = [[NSString alloc] initWithFormat:@"SID=%@;Domain=.google.com;path=/;expires=1600000000",googleSID];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
//	[request addRequestHeader:@"Cookie" value:cookie];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [request responseString];
		NSLog(@"Respond: %@", response);
	}else {
		NSLog(@"Error: %@", [error description]);
	}

*/	



	
}

@end
