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
#import "OCFeedCell.h"
#import "OCLoginController.h"
#import "TSMessage.h"
#import "TransparentToolbar.h"
#import "OCNewsHelper.h"
#import "Folder.h"
#import "Feed.h"
#import "FeedExtra.h"
#import "UIImageView+WebCache.h"
#import "AFNetworking.h"
#import "UIImage+Resource.h"

@interface OCFeedListController () <IIViewDeckControllerDelegate, UIActionSheetDelegate> {
    int currentFolderIndex;
    NSNumber *currentRenameId;
    int currentIndex;
    BOOL networkHasBeenUnreachable;
}

- (void) emailSupport:(NSNotification*)n;
- (void) networkSuccess:(NSNotification*)n;
- (void) networkError:(NSNotification*)n;
- (void) showMenu:(UIBarButtonItem*)sender event:(UIEvent*)event;
- (void) doHideRead;
- (void) doGoBack;
- (void) updatePredicate;
- (void) reachabilityChanged:(NSNotification *)n;
- (void) didBecomeActive:(NSNotification *)n;

@end

@implementation OCFeedListController

@synthesize addBarButtonItem;
@synthesize backBarButtonItem;
@synthesize editBarButtonItem;
@synthesize settingsPopover;
@synthesize feedRefreshControl;
@synthesize specialFetchedResultsController;
@synthesize foldersFetchedResultsController;
@synthesize feedsFetchedResultsController;
@synthesize gearActionSheet;
@synthesize addFolderAlertView;
@synthesize renameFolderAlertView;
@synthesize addFeedAlertView;

- (NSFetchedResultsController *)specialFetchedResultsController {
    if (!specialFetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"myId < 0"];
        [fetchRequest setPredicate:pred];
        
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        [fetchRequest setFetchBatchSize:2];
        
        specialFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                              managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                                sectionNameKeyPath:nil
                                                                                         cacheName:nil];
        specialFetchedResultsController.delegate = self;
    }
    return specialFetchedResultsController;
}

- (NSFetchedResultsController *)foldersFetchedResultsController {
    if (!foldersFetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];

        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        [fetchRequest setFetchBatchSize:20];
    
        foldersFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                              managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                                sectionNameKeyPath:nil
                                                                                         cacheName:nil];
        foldersFetchedResultsController.delegate = self;
    }
    return foldersFetchedResultsController;
}

- (NSFetchedResultsController *)feedsFetchedResultsController {
    if (!feedsFetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];

        NSPredicate *pred = [NSPredicate predicateWithFormat:@"myId > 0"];
        [fetchRequest setPredicate:pred];

        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        [fetchRequest setFetchBatchSize:20];
        
        feedsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
        feedsFetchedResultsController.delegate = self;
    }
    return feedsFetchedResultsController;
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
    //[self setEditing:NO animated:NO];
    
    currentIndex = -1;
    currentFolderIndex = 0;
    networkHasBeenUnreachable = NO;
    
    //UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    //fixedSpace.width = 5.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [NSArray arrayWithObjects:
                      flexibleSpace,
                      //self.infoBarButtonItem,
                      //fixedSpace,
                      self.addBarButtonItem,
                      
                      nil];
    
    TransparentToolbar *toolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
    toolbar.items = items;
    toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    } else {
        // Load resources for iOS 7 or later
        self.navigationItem.rightBarButtonItem = self.addBarButtonItem;
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 36, 0, 0);
    }
    
    self.refreshControl = self.feedRefreshControl;
    
    self.navigationItem.title = @"Feeds";
    //self.navigationController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.navigationController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;

    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableviewPress:)];
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
    
    UISwipeGestureRecognizer *swgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableviewSwipe:)];
    swgr.delegate = self;
    [self.tableView addGestureRecognizer:swgr];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emailSupport:) name:@"EmailSupport" object:nil];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"HideRead"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:AFNetworkingReachabilityDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    UINavigationController *navController = (UINavigationController*)self.viewDeckController.centerController;
    self.detailViewController = (OCArticleListController *)navController.topViewController;
    [self updatePredicate];
    self.viewDeckController.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    self.viewDeckController.delegate = self;
    [self.viewDeckController openLeftView];
    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.specialFetchedResultsController = nil;
    self.foldersFetchedResultsController = nil;
    self.feedsFetchedResultsController = nil;
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"HideRead"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
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
    } else {
        if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
            CGRect frame = self.navigationController.view.frame;
            frame.size.width = 300;
            self.navigationController.view.frame = frame;
            self.viewDeckController.leftSize = 300;
            self.viewDeckController.viewDeckController.leftSize = 20;
        } else {
            CGRect frame = self.navigationController.view.frame;
            frame.size.width = 300;
            self.navigationController.view.frame = frame;
            self.viewDeckController.leftSize = 300;
            self.viewDeckController.viewDeckController.leftSize = 0;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}
/*
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return @[@"Special", @"Folders", @"Feeds"];
}
*/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return [self.specialFetchedResultsController fetchedObjects].count;
            break;
        case 1:
            return [self.foldersFetchedResultsController fetchedObjects].count;
            break;
        case 2:
            return [self.feedsFetchedResultsController fetchedObjects].count;
            break;
            
        default:
            return 0;
            break;
    }
    
    return 0;
}

- (void)configureCell:(OCFeedCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    if (indexPath.section == 1) {
        Folder *folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
        [cell.imageView setImage:[UIImage imageNamed:@"folder"]];
        cell.textLabel.text = folder.name;
        cell.countBadge.value = folder.unreadCountValue;
    } else {
        Feed *feed;
        if (indexPath.section == 0) {
            if (indexPath.row < 2) {
                feed = [self.specialFetchedResultsController objectAtIndexPath:indexPathTemp];
            }
        } else {
            feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
        }
        NSString *faviconLink = feed.faviconLink;
        if ([faviconLink hasPrefix:@"http"]) {
            NSURL *faviconURL = [NSURL URLWithString:faviconLink] ;
            if (faviconURL) {
                if (cell.tag == indexPathTemp.row) {
                    [cell.imageView setImageWithURL:faviconURL placeholderImage:[UIImage imageNamed:@"favicon"]];
                }
            }
        } else {
            [cell.imageView setImage:[UIImage imageNamed:faviconLink]];
        }
        
        cell.countBadge.value = feed.unreadCountValue;
        
        if (feed.extra) {
            cell.textLabel.text = feed.extra.displayTitle;
        } else {
            cell.textLabel.text = feed.title;
        }
    }
    cell.delegate = self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    OCFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[OCFeedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    cell.tag = indexPath.row;
    cell.accessoryView = cell.countBadge;
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return (indexPath.section > 0);
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        if (indexPath.section == 1) {
            [[OCNewsHelper sharedHelper] deleteFolderOffline:[self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp]];
        } else if (indexPath.section == 2) {
            [[OCNewsHelper sharedHelper] deleteFeedOffline:[self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp]];
        }
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
    return NO;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentIndex = indexPath.row;
    NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    if (self.tableView.isEditing) {
        //[self showRenameForIndex:indexPath.row];
    } else {
        Folder *folder;
        Feed *feed;
        switch (indexPath.section) {
            case 0:
                feed = [self.specialFetchedResultsController objectAtIndexPath:indexPathTemp];
                if (!feed.extra) {
                    [[OCNewsHelper sharedHelper] addFeedExtra:feed];
                }
                self.detailViewController.feed = feed;
                [self.viewDeckController closeLeftView];
                break;
            case 1:
                folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
                currentFolderIndex = folder.myIdValue;
                self.navigationItem.title = folder.name;
                self.navigationItem.leftBarButtonItem = self.backBarButtonItem;
                [self updatePredicate];

                break;
            case 2:
                feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
                if (!feed.extra) {
                    [[OCNewsHelper sharedHelper] addFeedExtra:feed];
                }
                self.detailViewController.feed = feed;
                [self.viewDeckController closeLeftView];
                break;
                
            default:
                break;
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

- (void)tableView:(UITableView *)tableView moreOptionButtonPressedInRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    if ((indexPath.section == 1)) {
        Folder *folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
        currentRenameId = folder.myId;
        [[self.renameFolderAlertView textFieldAtIndex:0] setText:folder.name];
        [self.renameFolderAlertView show];
    } else if (indexPath.section == 2) {
        Feed *feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
        NSLog(@"Feed title: %@", feed.title);
        if (!feed.extra) {
            [[OCNewsHelper sharedHelper] addFeedExtra:feed];
        }
        NSLog(@"Feed title: %@", feed.extra.displayTitle);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle: nil];
            UINavigationController *navController = [storyboard instantiateViewControllerWithIdentifier: @"feedextra"];
            OCFeedSettingsController *settingsController = (OCFeedSettingsController*)navController.topViewController;
            [settingsController loadView];
            settingsController.feed = feed;
            settingsController.delegate = self;
            [self presentViewController:navController animated:YES completion:nil];
        } else {
            UINavigationController *navController = (UINavigationController *)self.settingsPopover.contentViewController;
            OCFeedSettingsController *settingsController = (OCFeedSettingsController *)navController.topViewController;
            settingsController.feed = feed;
            settingsController.delegate = self;
            
            [self.settingsPopover presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated:YES];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForMoreOptionButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"More";
}
/*
-(UIColor *)tableView:(UITableView *)tableView backgroundColorForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UIColor colorWithRed:0.18f green:0.67f blue:0.84f alpha:1.0f];
}
*/

#pragma mark - Actions

- (void)showMenu:(UIBarButtonItem *)sender event:(UIEvent *)event {
    self.gearActionSheet = nil;
    NSString *hideReadTitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"] ? @"Show Read" : @"Hide Read";
    self.gearActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Log In", @"Add Folder", @"Add Feed", hideReadTitle, nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.gearActionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [self.gearActionSheet showInView:self.viewDeckController.view];
    }
}

- (UIAlertView*)addFolderAlertView {
    if (!addFolderAlertView) {
        addFolderAlertView = [[UIAlertView alloc] initWithTitle:@"Add New Folder" message:@"Enter the name of the folder to add." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
        addFolderAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField * alertTextField = [addFolderAlertView textFieldAtIndex:0];
        alertTextField.keyboardType = UIKeyboardTypeDefault;
        alertTextField.placeholder = @"Folder name";
    }
    return addFolderAlertView;
}

- (UIAlertView*)renameFolderAlertView {
    if (!renameFolderAlertView) {
        renameFolderAlertView = [[UIAlertView alloc] initWithTitle:@"Rename Folder" message:@"Enter the new name of the folder." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
        renameFolderAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField * alertTextField = [renameFolderAlertView textFieldAtIndex:0];
        alertTextField.keyboardType = UIKeyboardTypeDefault;
        alertTextField.placeholder = @"Folder name";
    }
    return renameFolderAlertView;
}

- (UIAlertView*)addFeedAlertView {
    if (!addFeedAlertView) {
        addFeedAlertView = [[UIAlertView alloc] initWithTitle:@"Add New Feed" message:@"Enter the url of the feed to add." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add",nil];
        addFeedAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField * alertTextField = [addFeedAlertView textFieldAtIndex:0];
        alertTextField.keyboardType = UIKeyboardTypeURL;
        alertTextField.placeholder = @"http://example.com/feed";
    }
    return addFeedAlertView;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet isEqual:self.gearActionSheet]) {
        switch (buttonIndex) {
            case 0:
                [self doEdit:nil];
                break;
            case 1:
                [self.addFolderAlertView show];
                break;
            case 2:
                [self.addFeedAlertView show];
                break;
            case 3:
                [self doHideRead];
                break;
            default:
                break;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView isEqual:self.addFolderAlertView]) {
        if (buttonIndex == 1) {
            [[OCNewsHelper sharedHelper] addFolderOffline:[[alertView textFieldAtIndex:0] text]];
        }
    }
    if ([alertView isEqual:self.renameFolderAlertView]) {
        if (buttonIndex == 1) {
            [[OCNewsHelper sharedHelper] renameFolderOfflineWithId:currentRenameId To:[[alertView textFieldAtIndex:0] text]];
        }
    }
    if ([alertView isEqual:self.addFeedAlertView]) {
        if (buttonIndex == 1) {
            [[OCNewsHelper sharedHelper] addFeedOffline:[[alertView textFieldAtIndex:0] text]];
        }
    }
}

- (void)doGoBack {
    currentFolderIndex = 0;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.title = @"Feeds";
    [self updatePredicate];
}

- (void)doHideRead {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    BOOL hideRead = [prefs boolForKey:@"HideRead"];
    [prefs setBool:!hideRead forKey:@"HideRead"];
    [prefs synchronize];
}

- (IBAction)doEdit:(id)sender {
    //[self setEditing:YES animated:YES];
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    }
    [self.viewDeckController presentViewController: [storyboard instantiateViewControllerWithIdentifier:@"login"] animated:YES completion:nil];
}
/*
- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
//    if (editing) {
//        self.navigationItem.leftBarButtonItem = self.editButtonItem;
//    } else {
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 2.0f;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.editBarButtonItem,
                          flexibleSpace,
                          nil];
        
        TransparentToolbar *toolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
        toolbar.items = items;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
//    }
}
*/
- (IBAction)doRefresh:(id)sender {
    if (currentFolderIndex == 0) {
        [[OCNewsHelper sharedHelper] sync:nil];
    } else {
        [[OCNewsHelper sharedHelper] updateFolderWithId:[NSNumber numberWithInt:currentFolderIndex]];
    }
}

- (void) reloadRow:(NSIndexPath*)indexPath {
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if (currentIndex >= 0) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

}

- (IBAction)handleTableviewSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (currentFolderIndex > 0) {
        [self doGoBack];
    }
}
    
- (IBAction)handleTableviewPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    //http://stackoverflow.com/a/14364085/2036378 (why it's sometimes a good idea to retrieve the cell)
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        NSIndexPath *indexPathTemp = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        if (indexPath == nil) {
            NSLog(@"long press on table view but not on a row");
        } else {
            if ((indexPath.section == 1)) {
                Folder *folder = [self.foldersFetchedResultsController objectAtIndexPath:indexPathTemp];
                currentRenameId = folder.myId;
                [[self.renameFolderAlertView textFieldAtIndex:0] setText:folder.name];
                [self.renameFolderAlertView show];
            } else if (indexPath.section == 2) {
                //UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                //if (cell.isHighlighted) {
                    Feed *feed = [self.feedsFetchedResultsController objectAtIndexPath:indexPathTemp];
                    NSLog(@"Feed title: %@", feed.title);
                    if (!feed.extra) {
                        [[OCNewsHelper sharedHelper] addFeedExtra:feed];
                    }
                    NSLog(@"Feed title: %@", feed.extra.displayTitle);
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle: nil];
                        UINavigationController *navController = [storyboard instantiateViewControllerWithIdentifier: @"feedextra"];
                        OCFeedSettingsController *settingsController = (OCFeedSettingsController*)navController.topViewController;
                        [settingsController loadView];
                        settingsController.feed = feed;
                        settingsController.delegate = self;
                        [self presentViewController:navController animated:YES completion:nil];
                    } else {
                        UINavigationController *navController = (UINavigationController *)self.settingsPopover.contentViewController;
                        OCFeedSettingsController *settingsController = (OCFeedSettingsController *)navController.topViewController;
                        settingsController.feed = feed;
                        settingsController.delegate = self;
                        
                        [self.settingsPopover presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:[self view] permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                    }
                //}
            }
        }
    }
}

- (void) feedSettingsUpdate:(OCFeedSettingsController *)settings {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.settingsPopover dismissPopoverAnimated:YES];
    }
    [self.tableView reloadData]; // reloadRowsAtIndexPaths:@[[self.feedsFetchedResultsController indexPathForObject:settings.feed]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
    if([keyPath isEqual:@"HideRead"]) {
        [self updatePredicate];
    }
}

- (void)updatePredicate {
    NSPredicate *predFolder = [NSPredicate predicateWithFormat:@"folderId == %@", [NSNumber numberWithInt:currentFolderIndex]];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"]) {
        NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"myId > 0"];
        NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"unreadCount == 0"];
        NSArray *predArray = @[pred1, pred2];
        NSPredicate *pred3 = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
        NSPredicate *pred4 = [NSCompoundPredicate notPredicateWithSubpredicate:pred3];
        NSArray *predArray1 = @[predFolder, pred1, pred4];
        NSPredicate *pred5 = [NSCompoundPredicate andPredicateWithSubpredicates:predArray1];
        [[self.feedsFetchedResultsController fetchRequest] setPredicate:pred5];
    } else{
        NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"myId > 0"];
        NSArray *predArray = @[predFolder, pred1];
        NSPredicate *pred3 = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
        [[self.feedsFetchedResultsController fetchRequest] setPredicate:pred3];
    }
    
    if (currentFolderIndex > 0) {
        self.specialFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithValue:NO];
        self.foldersFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithValue:NO];
    } else {
        self.specialFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"myId < 0"];;
        self.foldersFetchedResultsController.fetchRequest.predicate = nil;
    }
    
    NSError *error;
    if (![[self specialFetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    if (![[self foldersFetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    if (![[self feedsFetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}

- (void)reachabilityChanged:(NSNotification *)n {
    NSNumber *s = n.userInfo[AFNetworkingReachabilityNotificationStatusItem];
    AFNetworkReachabilityStatus status = [s integerValue];
    
    if (status == AFNetworkReachabilityStatusNotReachable) {
        networkHasBeenUnreachable = YES;
        [TSMessage showNotificationInViewController:self.navigationController title:@"Unable to Reach Server" subtitle:@"Please check network connection and login." type:TSMessageNotificationTypeWarning];
    }
    if (status > AFNetworkReachabilityStatusNotReachable) {
        if (networkHasBeenUnreachable) {
            [TSMessage showNotificationInViewController:self.navigationController title:@"Server Reachable" subtitle:@"The network connection is working properly." type:TSMessageNotificationTypeSuccess];
            networkHasBeenUnreachable = NO;
        }
    }
}

- (void) didBecomeActive:(NSNotification *)n {
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"Server"].length == 0) {
        [self doEdit:nil];
    } else {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        if (board.URL) {
            if (![board.URL.absoluteString isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"PreviousPasteboardURL"]]) {
                [[NSUserDefaults standardUserDefaults] setObject:board.URL.absoluteString forKey:@"PreviousPasteboardURL"];
                NSArray *feedURLStrings = [self.feedsFetchedResultsController.fetchedObjects valueForKey:@"url"];
                NSLog(@"URLs: %@", feedURLStrings);
                if ([feedURLStrings indexOfObject:[board.URL absoluteString]] == NSNotFound) {
                    NSString *message = [NSString stringWithFormat:@"Would you like to add the feed: '%@'?", [board.URL absoluteString]];
                    [TSMessage showNotificationInViewController:self.navigationController
                                                          title:@"Add Feed"
                                                       subtitle:message
                                                          image:nil
                                                           type:TSMessageNotificationTypeMessage
                                                       duration:TSMessageNotificationDurationAutomatic
                                                       callback:nil
                                                    buttonTitle:@"Add"
                                                 buttonCallback:^{
                                                 [[OCNewsHelper sharedHelper] addFeedOffline:[board.URL absoluteString]];
                                             }
                                                     atPosition:TSMessageNotificationPositionTop
                                            canBeDismisedByUser:YES];
                }
            }
        }
    }
}

#pragma mark - Feeds maintenance

- (void) networkSuccess:(NSNotification *)n {
    [self.refreshControl endRefreshing];
    [self.detailViewController.refreshControl endRefreshing];
}

- (void)networkError:(NSNotification *)n {
    [self.refreshControl endRefreshing];
    [self.detailViewController.refreshControl endRefreshing];
    [TSMessage showNotificationInViewController:self.navigationController
                                          title:[n.userInfo objectForKey:@"Title"]
                                       subtitle:[n.userInfo objectForKey:@"Message"]
                                          image:nil
                                           type:TSMessageNotificationTypeError
                                       duration:TSMessageNotificationDurationEndless
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                            canBeDismisedByUser:YES];
}

- (void) emailSupport:(NSNotification *)n {
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    
    mailViewController.mailComposeDelegate = self;
    [mailViewController setToRecipients:[NSArray arrayWithObject:@"support@peterandlinda.com"]];
    [mailViewController setSubject:@"iOCNews Support Request"];
    [mailViewController setMessageBody:@"<Please state your problem here>\n\n\nI have attached my current subscriptions." isHTML:NO ];
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
        addBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageResourceNamed:@"gear"] style:UIBarButtonItemStylePlain target:self action:@selector(showMenu:event:)];
        addBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    
    return addBarButtonItem;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!backBarButtonItem) {
        backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Feeds" style:UIBarButtonItemStyleBordered target:self action:@selector(doGoBack)];
    }
    return backBarButtonItem;
}
/*
- (UIBarButtonItem *)editBarButtonItem {
    
    if (!editBarButtonItem) {
        editBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] style:UIBarButtonItemStylePlain target:self action:@selector(doEdit:)];
        editBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return editBarButtonItem;
}

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

- (UIPopoverController *) settingsPopover {
    if (!settingsPopover) {

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle: nil];
        settingsPopover = [[UIPopoverController alloc] initWithContentViewController:[storyboard instantiateViewControllerWithIdentifier: @"feedextra"]];
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // Load resources for iOS 6.1 or earlier
        } else {
            [settingsPopover setPopoverContentSize:CGSizeMake(320, 220)];
        }
    }
    return settingsPopover;
}

- (void)viewDeckController:(IIViewDeckController *)viewDeckController applyShadow:(CALayer *)shadowLayer withBounds:(CGRect)rect {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
    } else {
        shadowLayer.masksToBounds = NO;
        shadowLayer.shadowRadius = 2;
        shadowLayer.shadowOpacity = 0.9;
        shadowLayer.shadowColor = [[UIColor blackColor] CGColor];
        shadowLayer.shadowOffset = CGSizeZero;
        shadowLayer.shadowPath = [[UIBezierPath bezierPathWithRect:rect] CGPath];
    }
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController didOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    if (viewDeckSide == IIViewDeckLeftSide) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.detailViewController name:@"NetworkSuccess" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self.detailViewController name:@"NetworkError" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkSuccess:) name:@"NetworkSuccess" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkError:) name:@"NetworkError" object:nil];
    }
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController didCloseViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    if (viewDeckSide == IIViewDeckLeftSide) {
        OCArticleListController *alc = self.detailViewController;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NetworkSuccess" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NetworkError" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:alc selector:@selector(networkSuccess:) name:@"NetworkSuccess" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:alc selector:@selector(networkError:) name:@"NetworkError" object:nil];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSLog(@"Section: %d; Row: %d", indexPath.section, indexPath.row);

    UITableView *tableView = self.tableView;
    if (newIndexPath != nil && controller == self.foldersFetchedResultsController) {
        newIndexPath = [NSIndexPath indexPathForRow:[newIndexPath row] inSection:1];
        //if ([tableView cellForRowAtIndexPath:newIndexPath] == nil) {
        //    type = NSFetchedResultsChangeInsert;
        //}
    }
    if (newIndexPath != nil && controller == self.feedsFetchedResultsController) {
        newIndexPath = [NSIndexPath indexPathForRow:[newIndexPath row] inSection:2];
        //if ([tableView cellForRowAtIndexPath:newIndexPath] == nil) {
        //    type = NSFetchedResultsChangeInsert;
        //}
    }
    if (indexPath != nil && controller == self.foldersFetchedResultsController) {
        indexPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:1];
    }
    if (indexPath != nil && controller == self.feedsFetchedResultsController) {
        indexPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:2];
    }

    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(OCFeedCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

@end
