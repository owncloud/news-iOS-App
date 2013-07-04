//
//  FeedListController.m
//  FeedDeck
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
}

//- (NSString *)createUUID;
- (void) writeFeeds;
//- (void) showRenameForIndex:(int) index;
- (void) decreaseNewCount:(NSNotification*)n;
- (void) clearNewCount:(NSNotification*)n;
- (void) feedRefreshed:(NSNotification*)n;
- (void) feedRefreshedWithError:(NSNotification*)n;
- (void) emailSupport:(NSNotification*)n;

@end

@implementation OCFeedListController

@synthesize feeds = _feeds;
@synthesize addBarButtonItem;
@synthesize infoBarButtonItem;
@synthesize editBarButtonItem;
//@synthesize settingsPopover;
@synthesize feedRefreshControl;

- (NSMutableArray *) feeds {
    if (!_feeds) {
        //NSFileManager *fm = [NSFileManager defaultManager];
        //NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        //NSURL *docDir = [paths objectAtIndex:0];
        //docDir = [docDir URLByAppendingPathComponent:@"feeds.plist" isDirectory:NO];
        NSMutableArray *theFeeds;
        //if ([fm fileExistsAtPath:[docDir path]]) {
        //    theFeeds = [NSMutableArray arrayWithContentsOfURL:docDir];
        //} else {
            theFeeds = [[NSMutableArray alloc] init];
        //}
        //for (int i = 0; i < theFeeds.count; ++i) {
        //    NSMutableDictionary *dict = [theFeeds objectAtIndex:i];
        //    [dict setValue:[NSNumber numberWithBool:NO] forKey:@"Updating"];
        //    [dict setValue:[NSNumber numberWithBool:NO] forKey:@"Failure"];
            //[dict setValue:[NSNumber numberWithInt:0] forKey:@"NewCount"];
        //}
        self.feeds = theFeeds;
        //[self.tableView reloadData];
    }
    return _feeds;
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
    
    int status = [[OCAPIClient sharedClient] networkReachabilityStatus];
    
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
    NSDictionary *object = [self.feeds objectAtIndex:indexPath.row];
    
    BOOL haveIcon = NO;
    NSString *faviconLink = [object objectForKey:@"faviconLink"];
    NSLog(@"faviconLink: %@", faviconLink);
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
        cell.accessoryView = cell.countBadge;
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
            //[self writeFeeds];
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
        NSData *object = [self.feeds objectAtIndex:indexPath.row];
        self.detailViewController.detailItem = object;
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
    FDAboutPanel *aboutPanel = [[FDAboutPanel alloc] initWithFrame:myFrame title:@"About FeedDeck"];
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
            
            self.feeds = [NSMutableArray arrayWithArray:[jsonDict objectForKey:@"feeds"]];
            [self.refreshControl endRefreshing];
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

#pragma mark - Parser delegate

- (void) writeFeeds {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    NSURL *saveURL = [docDir URLByAppendingPathComponent:@"feeds.plist" isDirectory:NO];
    [self.feeds writeToURL:saveURL atomically:YES];
}

- (void) decreaseNewCount:(NSNotification*)n {
    //FDFeed *feed = [n.userInfo objectForKey:@"Feed"];
    [self.feeds replaceObjectAtIndex:currentIndex withObject:[n.userInfo objectForKey:@"Feed"]];
    //NSDictionary *dict = [_feeds objectAtIndex:currentIndex];
    //[dict setValue:[NSNumber numberWithInt:feed.newCount] forKey:@"NewCount"];
    //if (feed.error) {
    //    [dict setValue:[NSNumber numberWithBool:YES] forKey:@"Failure"];
    //} else {
    //    [dict setValue:[NSNumber numberWithBool:NO] forKey:@"Failure"];
    //}
    [self performSelectorOnMainThread:@selector(reloadRow:) withObject:[NSIndexPath indexPathForRow:currentIndex inSection:0] waitUntilDone:NO];
    //NSInvocationOperation *invOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(writeFeed:) object:feed];
    //[self.updateOperations.updateQueue addOperation:invOp];
    //invOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(writeFeeds) object:nil];
    //[self.updateOperations.updateQueue addOperation:invOp];
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
    
    DDXMLElement* title =[DDXMLNode elementWithName:@"title" stringValue:@"FeedDeck.opml"];
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
    [mailViewController setSubject:@"FeedDeck Support Request"];
    [mailViewController setMessageBody:@"<Please state your problem here>\n\n\nI have attached my current subscriptions." isHTML:NO ];
    [mailViewController addAttachmentData:[self createOPML] mimeType:@"text/xml" fileName:@"FeedDeck.opml"];
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
