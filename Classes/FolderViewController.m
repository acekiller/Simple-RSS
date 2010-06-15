//
//  FolderViewController.m
//  Simple RSS
//
//  Created by Manh Tuan Cao on 04/05/2010.
//  Copyright 2010 University of Sunderland. All rights reserved.
//

#import "FolderViewController.h"
#import "MySingleton.h"

#import "UserDefinedConst.h"
#import "EGODB.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "DetailViewController.h"
#import "DateHelper.h"
#import "GoogleReaderHelper.h"
#import "JSON.h"
#import "RSSParser.h"
#import "NewsViewController.h"
#import "Group.h"
#import "FolderCompositeCell.h"
#import "NewsListVC.h"

@implementation FolderViewController

@synthesize feeds, folders, feedParser,tmpCell, myProgressView;

@synthesize detailViewController;




- (void)dealloc {
	[feeds release];
	[folders release];
	[feedParser release];
	[networkQueue release];
	self.feedParser = nil;
	[detailViewController release];
	[myProgressView release];
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark -
#pragma mark Size for popover
// The size the view should be when presented in a popover.
- (CGSize)contentSizeForViewInPopoverView {
    return CGSizeMake(320.0, 600.0);
}


- (void) getFaviconFilePaths {
  NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FaviconsPath.plist"];

	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSMutableDictionary *paths;
	if ([fileManager fileExistsAtPath:filePath]) {
		paths = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
	} else {
		
		paths = [[NSMutableDictionary alloc] init];
	}
	
	[[MySingleton sharedInstance] setFaviconPaths:paths];

	[paths release];
	[fileManager release];

	NSLog(@"Number of item: %d", [[[MySingleton sharedInstance] faviconPaths] count]);
}

- (void)viewWillAppear:(BOOL) animated {
	NSLog(@"View Will appear");
	if (folderDidChange) {
		[self.tableView reloadData];			
	}

	folderDidChange = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	
    
    
    
	UIBarButtonItem *refreshButton =[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(startSyncing)] autorelease];
	

	self.navigationItem.rightBarButtonItem = refreshButton;
	self.title = @"Folder View";
	self.tableView.backgroundColor = [UIColor whiteColor];
	self.tableView.rowHeight = 45.0;	
	[self getFaviconFilePaths];

	
	
	myProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
	[myProgressView setProgress:0];
	networkQueue = [[ASINetworkQueue alloc] init];
	[networkQueue cancelAllOperations];
	[networkQueue setRequestDidFinishSelector:@selector(imageFetchComplete:)];
	[networkQueue setRequestDidFailSelector:@selector(requestDidFail:)];
	[networkQueue setDownloadProgressDelegate:myProgressView];
	[networkQueue setQueueDidFinishSelector:@selector(queueDidFinish:)];
	
	[networkQueue setMaxConcurrentOperationCount:1];
	[networkQueue setDelegate:self];
	
	

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		
	EGODB *db = [[EGODB alloc] init];
	feeds = [[NSMutableArray alloc] initWithArray:[db getUnreadFeeds]];
	folders = [[NSMutableArray alloc] initWithArray:[db getGroups]];
	
	[db release];
	

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedParsingArticles:) name:kNotificationFinishedParsingArticles object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedListDidChange:) name:kNotificationFeedListDidChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(folderListDidChange:) name:kNotificationAddedNewFolder object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsItemAdded:) name:kNotificationNewsItemAdded object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsMarkedAsRead:) name:kNotificationDidMarkNewsAsRead object:nil];

}



- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark Additional Methods

- (void) startSyncing {
	
	NSInteger timestamp = [DateHelper getTimeStampFromNDaysAgo:keepUnreadPeriod ];
	[[MySingleton sharedInstance] setTimeStamp:timestamp];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *SID = [defaults objectForKey:@"googleSID"];
	
	//	Code for getting TokenID	
	
	// Testing of getting all the Unread Item in one request

	NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
	[properties setValue:@"SID" forKey:NSHTTPCookieName];
	[properties setValue:SID forKey:NSHTTPCookieValue];
	[properties setValue:@".google.com" forKey:NSHTTPCookieDomain];
	[properties setValue:@"/" forKey:NSHTTPCookiePath];
	[properties setValue:[NSDate dateWithTimeIntervalSinceNow:84600*30]  forKey:NSHTTPCookieExpires];

	NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:[NSDictionary dictionaryWithDictionary:properties]];
	[properties release];
	// NSString *authString = [[NSString alloc] initWithFormat:@"GoogleLogin auth=%@",SID];
	NSString *authString = [[NSString alloc] initWithFormat:@"GoogleLogin auth=%@", SID];
	NSLog(@"authString = %@", authString);

	NSString *cookieStr = [[NSString alloc] initWithFormat:@"SID=%@",SID];

	
	// request for tokenID
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:kURLGetTokenID]] autorelease];
	NSLog(@"Number of cookies for this URL: %d", [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[request url] ] count]);
	[request addRequestHeader:@"Cookie" value:cookieStr];

	[request setUseCookiePersistence:YES];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	NSDictionary *info = [[[NSDictionary alloc] initWithObjectsAndKeys:@"TokenID", @"RequestType",nil] autorelease];
	[request setUserInfo:info];
	[networkQueue addOperation:request];
	//Request for getting list of subscription
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:kURLGetUserInfo]] autorelease];
	//[request addRequestHeader:@"Authorization" value:authString];	
	[request addRequestHeader:@"Cookie" value:cookieStr];
	
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	
	info = [[[NSDictionary alloc] initWithObjectsAndKeys:@"User Info", @"RequestType",nil] autorelease];
	[request setUserInfo:info];
	[networkQueue addOperation:request];
	
	
	
	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:kURLGetSubscription]] autorelease];
	//[request addRequestHeader:@"Authorization" value:authString];	
	[request addRequestHeader:@"Cookie" value:cookieStr];

	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	
	info = [[[NSDictionary alloc] initWithObjectsAndKeys:@"Subscription", @"RequestType",nil] autorelease];
	[request setUserInfo:info];
	[networkQueue addOperation:request];


	

//Request for getting Tag List	
	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:kURLGetTagList]] autorelease];
	[request addRequestHeader:@"Cookie" value:cookieStr];
//	[request addRequestHeader:@"Authorization" value:authString];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	info = [[[NSDictionary alloc] initWithObjectsAndKeys:@"TagList", @"RequestType",nil] autorelease];
	[request setUserInfo:info];
	[networkQueue addOperation:request];
	
//Request for getting Unread Items Id 
	
	
	


	request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:kURLgetUnreadItemIDsFormat, timestamp]]] autorelease];
//	[request addRequestHeader:@"Authorization" value:authString];													
													
	NSLog(@"Get Unread URL: %@",[NSString stringWithFormat:kURLgetUnreadItemIDsFormat, timestamp]);
	[request addRequestHeader:@"Cookie" value:cookieStr];
	[request setRequestCookies:[NSMutableArray arrayWithObject:cookie]];
	info = [[[NSDictionary alloc] initWithObjectsAndKeys:@"UnreadItemsID", @"RequestType",nil] autorelease];
	[request setUserInfo:info];
	[networkQueue addOperation:request];	
	
	
	[networkQueue go];
	
	[cookieStr release];
	[cookie release];
	[authString release];
	
}


- (void)imageFetchComplete:(ASIHTTPRequest *)request
{
	NSLog(@"Request Type: ------------ %@ ------------",[[request userInfo] objectForKey:@"RequestType"]);
	NSLog(@"Progress :%f", [myProgressView progress] );
	if ([[[request userInfo] objectForKey:@"RequestType"] isEqualToString:@"Subscription"]) {
		
		NSLog(@"Calling function to process Subscription parsing....");
		[RSSParser processSubscription:[request responseString] ];
	}else 	if ([[[request userInfo] objectForKey:@"RequestType"] isEqualToString:@"TagList"]) {
		[RSSParser processTagList:[request responseString]];
		NSLog(@"Calling function to process Tag List parsing....");
	}else 	if ([[[request userInfo] objectForKey:@"RequestType"] isEqualToString:@"UnreadItemsID"]) {
		[RSSParser processUnreadItemIDs:[request responseString] withNetworkQueue:networkQueue ];
		NSLog(@"Calling function to process Unread Item ID parsing....");
	}else if ([[[request userInfo] objectForKey:@"RequestType"] isEqualToString:@"POSTUnreadIDs"]) {
		
		NSLog(@"Get Respond from POST request : %d byte", [[request responseString] length]);
		[RSSParser addNewsItemsToDatabase: [request responseString]];
	}else if ([[[request userInfo] objectForKey:@"RequestType"] isEqualToString:@"Favicon"]) {
		
		[RSSParser processDownloadedFavicon:request];		
		//NSLog(@"Remaining request : %d", [[request queue] count]);
	}else {
	
	
		NSLog(@"Calling something else...");
	}
	NSLog(@"Downloaded bytes: %d", [[request responseString] length]);
	NSLog(@"%@",[request responseString]);
		
	
}

- (void)requestDidFail:(ASIHTTPRequest *)request {
	NSLog(@"Request did failed with URL : %@", [[request url] absoluteURL]);
	NSLog(@"Failed with error: %@", [[request error] description]);
	
}

- (void)authenticationNeededForRequest:(ASIHTTPRequest *)request {
	[request setUsername:@"caomanhtuanbsb"];
	[request setPassword:@"tu4ncm"];
	[request retryUsingSuppliedCredentials];
}

- (void) queueDidFinish:(ASINetworkQueue *)queue {
	NSLog(@"Queue did finished");
	[RSSParser addFaviconRequests:queue];
	[queue setQueueDidFinishSelector:@selector(faviconQueueDidFinish:)];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	
}

- (void)faviconQueueDidFinish: (ASINetworkQueue *)queue {
	NSLog(@"Did finish downloading Favicon");
	
	NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FaviconsPath.plist"];
	
	[[[MySingleton sharedInstance] faviconPaths] writeToFile:filePath atomically:YES];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	//Reset queueDidFinishSelector
	[queue setQueueDidFinishSelector:@selector(queueDidFinish:)];
	
	
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (folders != nil) {
		return [folders count];
	}
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"FolderCell";

	FolderCompositeCell *cell = (FolderCompositeCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[FolderCompositeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	
	cell.titleLabel = [[folders objectAtIndex:indexPath.row] title];
	cell.countLabel = [NSString stringWithFormat:@"%d",[[folders objectAtIndex:indexPath.row] unreadCount]];
	cell.iconView = [UIImage imageNamed:@"Folder1.png"];
	
	
	return cell;
  
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 	EGODB *db = [[EGODB alloc] init];
	
	/*NewsViewController *newsVC = [[NewsViewController alloc] initWithStyle:UITableViewStylePlain];
	//[newsVC setParentFeed:[feeds objectAtIndex:indexPath.row]];
	
	[newsVC setParentFolder:[db getFullGroupWithGroupID:[[folders objectAtIndex:indexPath.row] groupID]]];
	
	[self.navigationController pushViewController:newsVC 	 animated:YES];
	newsVC.detailVC = detailViewController;*/
	NewsListVC *newsVC = [[NewsListVC alloc] initWithStyle:UITableViewStylePlain];
	[newsVC.newsList addObjectsFromArray:[db getNewsItemsWithGroupID:[[folders objectAtIndex:indexPath.row] groupID]]];
	newsVC.feedsDict = [db getFeedNamesWithGroupID:[[folders objectAtIndex:indexPath.row] groupID]];
	newsVC.groupID = [[folders objectAtIndex:indexPath.row] groupID];
	newsVC.detailVC = detailViewController;
	[self.navigationController pushViewController:newsVC animated:YES];

	 
	[newsVC release];
	[db release];
}



#pragma mark -
#pragma mark <FeedParserDelegate> Methods

#pragma mark -
#pragma mark Notification implementation

- (void) finishedParsingArticles:(NSNotification *) notification {
	NSLog(@"Running in %s at Line %d",__FUNCTION__, __LINE__ );
}

- (void) feedListDidChange:(NSNotification *) notification {
	NSLog(@"Feed List Did changed");
	}

- (void) folderListDidChange:(NSNotification *) notification {
	
	NSLog(@"Folder did change");
	EGODB *db = [[EGODB alloc] init];
	[folders removeAllObjects];
	[folders addObjectsFromArray:[db getGroups]];

	[self.tableView reloadData];
	[db release];
	
}

-(void) newsMarkedAsRead:(NSNotification *)notification {
	NSString *aGroupID = [notification object];
	for (int i = 0; i < [folders count]; i++) {
		if ([[[folders objectAtIndex:i] groupID] isEqualToString:aGroupID]) {
			int count =[[folders objectAtIndex:i] unreadCount] ;
			count--;
			[[folders objectAtIndex:i] setUnreadCount:count];
			folderDidChange = YES;
			break;
		}
	}
}

- (void) newsItemAdded:(NSNotification *) notification {
	NSString *feedID = [[notification object] feedID];
	for (int i = 0; i < [folders count]; i++) {
		if ([[[folders objectAtIndex:i] feedsDict] objectForKey:feedID]) {
			int count= [[folders objectAtIndex:i] unreadCount]; 
			[[folders objectAtIndex:i] setUnreadCount:count +1] ;
			NSIndexPath *durPath = [NSIndexPath indexPathForRow:i inSection:0];
			NSArray *paths = [NSArray arrayWithObject:durPath];
			[self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
			
		}
					
	}

	
}


@end

