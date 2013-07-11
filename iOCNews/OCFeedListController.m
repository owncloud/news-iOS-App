//
//  FeedListController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2013 Peter Hedlund peter.hedlund@me.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *************************************************************************/

#import "OCFeedListController.h"
#import "IIViewDeckController.h"
#import "AppDelegate.h"
#import "OCFeedCell.h"
#import "AFNetworking.h"
#import "OCAPIClient.h"
#import "OCLoginController.h"

@interface OCFeedListController () {
    int parserCount;
    int currentIndex;
    BOOL haveSyncData;
}

//- (NSString *)createUUID;
- (void) writeFeeds;
- (void) updateItems;
- (void) writeItems;
//- (void) showRenameForIndex:(int) index;
- (void) decreaseNewCount:(NSNotification*)n;
- (void) processUnreadCountChange:(NSNotification*)n;
- (void) clearNewCount:(NSNotification*)n;
- (void) feedRefreshed:(NSNotification*)n;
- (void) feedRefreshedWithError:(NSNotification*)n;
- (void) emailSupport:(NSNotification*)n;
- (void) starredChange:(NSNotification*)n;

@end

@implementation OCFeedListController

@synthesize feeds = _feeds;
@synthesize items = _items;
@synthesize addBarButtonItem;
@synthesize infoBarButtonItem;
@synthesize editBarButtonItem;
//@synthesize settingsPopover;
@synthesize feedRefreshControl;

- (NSMutableArray *) feeds {
    if (!_feeds) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        docDir = [docDir URLByAppendingPathComponent:@"feeds.plist" isDirectory:NO];
        NSMutableArray *theFeeds;
        if ([fm fileExistsAtPath:[docDir path]]) {
            theFeeds = [NSKeyedUnarchiver unarchiveObjectWithFile:[docDir path]];
            haveSyncData = YES;
        } else {
            theFeeds = [[NSMutableArray alloc] init];
            haveSyncData = NO;
        }
        _feeds = theFeeds;
        [self.tableView reloadData];
    }
    return _feeds;
}

- (NSMutableArray *) items {
    if (!_items) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        docDir = [docDir URLByAppendingPathComponent:@"items.plist" isDirectory:NO];
        if ([fm fileExistsAtPath:[docDir path]]) {
            _items = [NSKeyedUnarchiver unarchiveObjectWithFile:[docDir path]];
        } else {
            _items = [NSMutableArray new];
        }
    }
    return _items;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.allowsSelection = YES;
    self.tableView.allowsSelectionDuringEditing = YES;

    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self setEditing:NO animated:NO];
    
    currentIndex = -1;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [NSArray arrayWithObjects:
                      flexibleSpace,
                      //self.infoBarButtonItem,
                      //fixedSpace,
                      self.addBarButtonItem,
                      
                      nil];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
    toolbar.items = items;
    toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

    self.refreshControl = self.feedRefreshControl;
    
    self.navigationItem.title = @"Feeds";
    //self.navigationController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.navigationController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;

    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decreaseNewCount:) name:@"DecreaseNewCount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearNewCount:) name:@"ClearNewCount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedRefreshed:) name:@"FeedRefreshed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedRefreshedWithError:) name:@"FeedRefreshedWithError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emailSupport:) name:@"EmailSupport" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(starredChange:) name:@"StarredChange" object:nil];
    
    int status = [[OCAPIClient sharedClient] networkReachabilityStatus];
    NSLog(@"Server status: %i", status);
    
    haveSyncData = NO;
    
    IIViewDeckController *topDeckController = (IIViewDeckController *)self.viewDeckController.centerController;
    UINavigationController *navController = (UINavigationController*)topDeckController.leftController;
    self.detailViewController = (OCArticleListController *)navController.topViewController;
    //[self.detailViewController writeCssTemplate];
    
    self.viewDeckController.leftSize = 320;
    [self.viewDeckController openLeftView];

    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
    if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        CGRect frame = self.navigationController.view.frame;
        frame.size.width = 320;
        self.navigationController.view.frame = frame;
        self.viewDeckController.leftSize = 320;
	} else {
        CGRect frame = self.navigationController.view.frame;
        frame.size.width = 320;
        self.navigationController.view.frame = frame;
        self.viewDeckController.leftSize = 320;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.feeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    OCFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[OCFeedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    cell.tag = indexPath.row;
    // Configure the cell...
    cell.accessoryView = cell.countBadge;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"All Articles";
        [cell.imageView setImage:[UIImage imageNamed:@"favicon"]];
        NSArray *unreadCounts = [self.feeds valueForKey:@"unreadCount"];
        cell.countBadge.value = [[unreadCounts valueForKeyPath:@"@sum.self"] integerValue];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Starred";
        [cell.imageView setImage:[UIImage imageNamed:@"favicon"]];
        NSArray *starredCounts = [self.items valueForKey:@"starred"];
        cell.countBadge.value = [[starredCounts valueForKeyPath:@"@sum.self"] integerValue];
    } else {
        NSDictionary *object = [self.feeds objectAtIndex:indexPath.row - 2];
        
        BOOL haveIcon = NO;
        NSString *faviconLink = [object objectForKey:@"faviconLink"];
        //NSLog(@"faviconLink: %@", faviconLink);
        if (![faviconLink isKindOfClass:[NSNull class]]) {
            
            if ([faviconLink hasPrefix:@"http"]) {
                NSURL *faviconURL = [NSURL URLWithString:faviconLink] ;
                if (faviconURL) {
                    if (cell.tag == indexPath.row) {
                        haveIcon = YES;
                        [cell.imageView setImageWithURL:faviconURL placeholderImage:[UIImage imageNamed:@"favicon"]];
                    }
                }
            }
        }
        if (!haveIcon) {
            [cell.imageView setImage:[UIImage imageNamed:@"favicon"]];
        }
        
        /*
         if ([[object valueForKey:@"Updating"] boolValue] == YES) {
         cell.accessoryView = cell.activityIndicator;
         [cell.activityIndicator startAnimating];
         } else { */
        cell.countBadge.value = [[object valueForKey:@"unreadCount"] integerValue];
        //[cell.activityIndicator stopAnimating];
        /*    }
         
         if ([[object valueForKey:@"Failure"] boolValue] == YES) {
         cell.detailTextLabel.text = @"Failed to update feed";
         } else {
         cell.detailTextLabel.text = @"";
         }
         */
        cell.textLabel.text = [object valueForKey:@"title"];
        
    }
    
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0);
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *object = [self.feeds objectAtIndex:indexPath.row];
        NSString *myId = [object valueForKey:@"id"];
        
        OCAPIClient *client = [OCAPIClient sharedClient];
        
        NSMutableURLRequest *request = [client requestWithMethod:@"DELETE" path:[NSString stringWithFormat:@"feeds/%@", myId] parameters:nil];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.feeds removeObjectAtIndex:indexPath.row];
            [self writeFeeds];
            // Delete the row from the data source
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

            NSLog(@"Success");
        } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure"); 
        }];

        [client enqueueHTTPRequestOperation:operation];

    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    //
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentIndex = indexPath.row;
    if (self.tableView.isEditing) {
        //[self showRenameForIndex:indexPath.row];
    } else {
        if (indexPath.row == 0) {
            NSArray *unreadCounts = [self.feeds valueForKey:@"unreadCount"];
            int totalUnread = [[unreadCounts valueForKeyPath:@"@sum.self"] integerValue];
            NSMutableDictionary *allFeed = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"All Articles", @"title", [NSNumber numberWithInt:totalUnread], @"unreadCount", nil];
            self.detailViewController.items = self.items;
            self.detailViewController.feed = allFeed;
        } else if (indexPath.row == 1) {
            NSArray *feedItems = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"starred = 1"]];
            NSArray *unreadCounts = [feedItems valueForKey:@"unread"];
            int unread = [[unreadCounts valueForKeyPath:@"@sum.self"] integerValue];
            NSMutableDictionary *starredFeed = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Starred", @"title", [NSNumber numberWithInt:unread], @"unreadCount", nil];
            self.detailViewController.items = [NSMutableArray arrayWithArray:feedItems];
            self.detailViewController.feed = (NSMutableDictionary *)starredFeed;
        } else {
            NSData *object = [self.feeds objectAtIndex:indexPath.row - 2];
            NSString *feedId = [object valueForKey:@"id"];
            NSArray *feedItems = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"feedId = %@", feedId]];
            NSLog(@"FeedId: %@; Count: %i", feedId, feedItems.count);
            self.detailViewController.items = [NSMutableArray arrayWithArray:feedItems];
            self.detailViewController.feed = (NSMutableDictionary *)object;
        }
        [self.viewDeckController closeLeftView];
            
    }

}

#pragma mark - Actions

- (IBAction)doAdd:(id)sender {
    if ([[OCAPIClient sharedClient] networkReachabilityStatus] > 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add New Feed" message:@"Enter the url of the feed to add." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField * alertTextField = [alert textFieldAtIndex:0];
        alertTextField.keyboardType = UIKeyboardTypeURL;
        alertTextField.placeholder = @"http://example.com/feed";
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *newID = [[alertView textFieldAtIndex:0] text];
        
        OCAPIClient *client = [OCAPIClient sharedClient];        

        NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:[NSString stringWithFormat:@"feeds/3"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:newID, @"url", newID, @"folderId", 0, nil]];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
           
            NSLog(@"Feeds: %@", JSON);
            NSDictionary *jsonDict = (NSDictionary *) JSON;
            NSMutableArray *newFeeds = [jsonDict objectForKey:@"feeds"];
            NSDictionary *newFeed = [newFeeds objectAtIndex:0];
            [self.feeds addObject:newFeed];
            [self writeFeeds];
            [self.tableView reloadData];

        } failure:nil];
        
        [client enqueueHTTPRequestOperation:operation];

    }
}

- (IBAction)doInfo:(id)sender {
    /*
    CGRect myFrame;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        myFrame = CGRectMake(0, 0, 1024, 748);
    } else {
        myFrame = CGRectMake(0, 0, 768, 1004);
    }
    AppDelegate* myDelegate = (((AppDelegate*) [UIApplication sharedApplication].delegate));
    FDAboutPanel *aboutPanel = [[FDAboutPanel alloc] initWithFrame:myFrame title:@"About iOCNews"];
    [myDelegate.window.rootViewController.view addSubview:aboutPanel];
	[aboutPanel showFromPoint:CGPointMake(250, 30)];
     */
}

- (IBAction)doEdit:(id)sender {
    //[self setEditing:YES animated:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    [self presentViewController: [storyboard instantiateViewControllerWithIdentifier:@"login"] animated:YES completion:nil];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
    } else {
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 2.0f;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.editBarButtonItem,
                          flexibleSpace,
                          nil];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
        toolbar.items = items;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    }
}

- (IBAction)doRefresh:(id)sender {
    
    OCAPIClient *client = [OCAPIClient sharedClient];
    
    if ([client networkReachabilityStatus] > 0) {
        NSMutableURLRequest *request = [client requestWithMethod:@"GET" path:@"feeds" parameters:nil];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            NSLog(@"Feeds: %@", JSON);
            NSDictionary *jsonDict = (NSDictionary *) JSON;
            NSArray *newFeeds = [NSMutableArray arrayWithArray:[jsonDict objectForKey:@"feeds"]];
            NSMutableArray *mutableArray = [newFeeds mutableCopy];
            
            [newFeeds enumerateObjectsUsingBlock:^(NSDictionary *feed, NSUInteger idx, BOOL *stop ) {
                [mutableArray replaceObjectAtIndex:idx withObject:[feed mutableCopy]];
            }];
            
            self.feeds = mutableArray;

            [self writeFeeds];
            [self updateItems];
            //[self.refreshControl endRefreshing];
            [self.tableView reloadData];
            
        } failure:nil];
        [client enqueueHTTPRequestOperation:operation];
    } else {
        [self.refreshControl endRefreshing];
    }
    
}

- (void) reloadRow:(NSIndexPath*)indexPath {
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if (currentIndex >= 0) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

}

#pragma mark - Feeds maintenance

- (void) writeFeeds {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    NSURL *saveURL = [docDir URLByAppendingPathComponent:@"feeds.plist" isDirectory:NO];
    [NSKeyedArchiver archiveRootObject:self.feeds toFile:[saveURL path]];
}

- (void) updateItems {
    if (([[OCAPIClient sharedClient] networkReachabilityStatus] > 0)) {
        OCAPIClient *client = [OCAPIClient sharedClient];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[[NSUserDefaults standardUserDefaults] stringForKey:@"LastModified"], @"lastModified",
                                [NSNumber numberWithInt:3], @"type",
                                [NSNumber numberWithInt:0], @"id", nil];
        
        NSMutableURLRequest *request = [client requestWithMethod:@"GET" path:@"items/updated" parameters:params];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            //NSLog(@"Updated Items: %@", JSON);
            NSDictionary *jsonDict = (NSDictionary *) JSON;
            NSArray *newItems = [NSArray arrayWithArray:[jsonDict objectForKey:@"items"]];
            
            if (newItems.count > 0) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.lastModified == %@.@max.lastModified", newItems];
                NSString *lastModified = [[[newItems filteredArrayUsingPredicate:predicate] objectAtIndex:0] valueForKey:@"lastModified"];
                //NSDictionary *newestItem = [newItems objectAtIndex:0];
                [[NSUserDefaults standardUserDefaults] setObject:lastModified forKey:@"LastModified"];
            }
            
            NSMutableArray *mutableArray = [newItems mutableCopy];
            
            [newItems enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop ) {
                [mutableArray replaceObjectAtIndex:idx withObject:[item mutableCopy]];
            }];
            
            [mutableArray addObjectsFromArray:self.items];
            self.items = mutableArray;
            [self writeItems];
            [self.refreshControl endRefreshing];
            
        } failure:nil];
        [client enqueueHTTPRequestOperation:operation];
    }

}

- (void) writeItems {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    NSURL *saveURL = [docDir URLByAppendingPathComponent:@"items.plist" isDirectory:NO];
    [NSKeyedArchiver archiveRootObject:self.items toFile:[saveURL path]];
}

- (void) decreaseNewCount:(NSNotification*)n {
    NSInvocationOperation *invOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processUnreadCountChange:) object:n];
    [invOp setCompletionBlock:^ {
        [[OCAPIClient sharedClient] putPath:@"items/read/multiple" parameters:[NSDictionary dictionaryWithObject:[n.userInfo valueForKey:@"itemIds"] forKey:@"items"] success:nil failure:nil];
    }];
    [[OCAPIClient sharedClient].operationQueue addOperation:invOp];
}

- (void) processUnreadCountChange:(NSNotification *)n {
    NSArray *feedIds = [n.userInfo valueForKey:@"feedIds"];
    NSArray *itemIds = [n.userInfo valueForKey:@"itemIds"];

    __block NSArray *a = [self.items valueForKey:@"id"];
    
    [itemIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSInteger index = [a indexOfObject:obj];
        NSNumber *unread = [[self.items objectAtIndex:index] valueForKey:@"unread"];
        if ([unread intValue] == 1) {
            [[self.items objectAtIndex:index] setValue:[NSNumber numberWithInt:0] forKey:@"unread"];
        }
    }];

    [self.detailViewController.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    [self writeItems];

    a = [self.feeds valueForKey:@"id"];
    [feedIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSInteger index = [a indexOfObject:obj];

        NSArray *feedItems = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"feedId = %@", obj]];
        NSArray *unreadItems = [feedItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"unread = 1"]];

        [[self.feeds objectAtIndex:index] setValue:[NSNumber numberWithInt:[unreadItems count]] forKey:@"unreadCount"];
        [self performSelectorOnMainThread:@selector(reloadRow:) withObject:[NSIndexPath indexPathForRow:index + 2 inSection:0] waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(reloadRow:) withObject:[NSIndexPath indexPathForRow:0 inSection:0] waitUntilDone:NO];
    }];    
    [self writeFeeds];

}

- (void) clearNewCount:(NSNotification*)n {
    [self decreaseNewCount:n];
}

- (void) feedRefreshed:(NSNotification*)n {
    [self decreaseNewCount:n];
}

- (void) feedRefreshedWithError:(NSNotification*)n {
    [self decreaseNewCount:n];
}

- (void) starredChange:(NSNotification *)n {
    NSDictionary *item = [n.userInfo valueForKey:@"item"];
    NSString *feedId = [item valueForKey:@"feedId"];
    NSString *guidHash = [item valueForKey:@"guidHash"];
    NSString *path;
    if ([[item valueForKey:@"starred"] isEqual:[NSNumber numberWithInt:1]]) {
         ///items/{feedId}/{guidHash}/star
        path = [NSString stringWithFormat:@"items/%@/%@/star", feedId, guidHash];
    } else {
        // /items/{feedId}/{guidHash}/unstar
        path = [NSString stringWithFormat:@"items/%@/%@/unstar", feedId, guidHash];
    }
    [[OCAPIClient sharedClient] putPath:path parameters:nil success:nil failure:nil];
    [self performSelectorOnMainThread:@selector(reloadRow:) withObject:[NSIndexPath indexPathForRow:1 inSection:0] waitUntilDone:NO];
}

#pragma mark - OPML handling

- (void) loadOPML {
/*    NSInvocationOperation *invOp;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    
    //Move files out of the Inbox and remove the Inbox folder
    NSString *inboxPath  = [[docDir path] stringByAppendingPathComponent:@"Inbox/"];
    NSDirectoryEnumerator *inboxEnum = [[NSFileManager defaultManager] enumeratorAtPath: inboxPath];
    NSString *file;
    while (file = [inboxEnum nextObject]) {
        NSString *origFilePath = [inboxPath stringByAppendingPathComponent:[file lastPathComponent]];

        NSData *data = [NSData dataWithContentsOfFile:origFilePath];
    
        DDXMLDocument *opmlDoc = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
        NSArray *outlineNodes = [opmlDoc nodesForXPath:@"//outline[@xmlUrl]" error:nil];
        for (DDXMLElement *element in outlineNodes) {
            if ([element attributeForName:@"xmlUrl"].stringValue != nil) {
                NSLog(@"Feed title: %@", [element attributeForName:@"text"].stringValue);

                FDFeed *newFeed = [[FDFeed alloc] init];
                newFeed.url = [NSURL URLWithString:[element attributeForName:@"xmlUrl"].stringValue];
                newFeed.guid = [self createUUID];
                newFeed.title = [element attributeForName:@"text"].stringValue;
                
                NSMutableDictionary *newObject = [NSMutableDictionary dictionaryWithObjectsAndKeys: newFeed.title, @"Title",
                                                  [element attributeForName:@"htmlUrl"].stringValue, @"FeedLink",
                                                  [element attributeForName:@"xmlUrl"].stringValue, @"XMLUrl",
                                                  newFeed.guid, @"GUID",
                                                  [NSNumber numberWithBool:NO], @"Updating",
                                                  [NSNumber numberWithBool:NO], @"Failure",
                                                  [NSNumber numberWithInt:0], @"NewCount",
                                                  [NSNumber numberWithBool:NO], @"FullArticle",
                                                  [NSNumber numberWithBool:NO], @"PreferReader", nil];
                
                
                [self.feeds addObject:newObject];
                invOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(writeFeed:) object:newFeed];
                [self.updateOperations.updateQueue addOperation:invOp];
            }
        }
    }
    [[NSFileManager defaultManager] removeItemAtPath:inboxPath error:nil];

    invOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(writeFeeds) object:nil];
    [self.updateOperations.updateQueue addOperation:invOp];

    [self.tableView reloadData]; */
}

- (NSData*) createOPML {
/*
    DDXMLDocument* document = [[DDXMLDocument alloc] initWithXMLString:@"<opml/>" options:0 error:nil];
    DDXMLElement* root = [document rootElement];
    [root addAttribute:[DDXMLNode attributeWithName:@"version" stringValue:@"2.0"]];
    DDXMLElement* head =[DDXMLNode elementWithName:@"head"];
    DDXMLElement* body =[DDXMLNode elementWithName:@"body"];
    
    [root addChild:head];
    [root addChild:body];
    
    DDXMLElement* title =[DDXMLNode elementWithName:@"title" stringValue:@"iOCNews.opml"];
    [head addChild:title];

    for (NSDictionary *feedObject in self.feeds) {
        DDXMLElement* outline =[DDXMLNode elementWithName:@"outline"];
        [outline addAttribute:[DDXMLNode attributeWithName:@"text" stringValue:[feedObject objectForKey:@"Title"]]];
        [outline addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"rss"]];
        [outline addAttribute:[DDXMLNode attributeWithName:@"xmlUrl" stringValue:[feedObject objectForKey:@"XMLUrl"]]];
        if ([feedObject objectForKey:@"FeedLink"]) {
            [outline addAttribute:[DDXMLNode attributeWithName:@"htmlUrl" stringValue:[feedObject objectForKey:@"FeedLink"]]];
        }
        [body addChild:outline];
    }

    return [document XMLData]; */
    return nil;
}

- (void) emailSupport:(NSNotification *)n {
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    
    mailViewController.mailComposeDelegate = self;
    [mailViewController setToRecipients:[NSArray arrayWithObject:@"support@peterandlinda.com"]];
    [mailViewController setSubject:@"iOCNews Support Request"];
    [mailViewController setMessageBody:@"<Please state your problem here>\n\n\nI have attached my current subscriptions." isHTML:NO ];
    [mailViewController addAttachmentData:[self createOPML] mimeType:@"text/xml" fileName:@"iOCNews.opml"];
    mailViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentViewController:mailViewController animated:YES completion:nil];

}
#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Toolbar Buttons

- (UIBarButtonItem *)addBarButtonItem {
    
    if (!addBarButtonItem) {
        addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAdd:)];
    }
    
    return addBarButtonItem;
}

- (UIBarButtonItem *)infoBarButtonItem {
    
    if (!infoBarButtonItem) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [button addTarget:self action:@selector(doInfo:) forControlEvents:UIControlEventTouchUpInside];
        infoBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return infoBarButtonItem;
}

- (UIBarButtonItem *)editBarButtonItem {
    
    if (!editBarButtonItem) {
        editBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] style:UIBarButtonItemStylePlain target:self action:@selector(doEdit:)];
        editBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return editBarButtonItem;
}
/*
- (UIPopoverController *) settingsPopover {
    if (!settingsPopover) {
        
        FDFeedSettingsController *settingsController = [[FDFeedSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
        UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsController];
        settingsNavController.topViewController.navigationItem.title = @"Edit Feed";
        settingsNavController.topViewController.navigationItem.rightBarButtonItem = settingsController.saveBarButtonItem;
        settingsController.delegate = self;
        settingsPopover = [[UIPopoverController alloc] initWithContentViewController:settingsNavController];

    }
    return settingsPopover;
}
*/
- (UIRefreshControl *)feedRefreshControl {
    if (!feedRefreshControl) {
        feedRefreshControl = [[UIRefreshControl alloc] init];
        [feedRefreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    }
    
    return feedRefreshControl;
}

@end
