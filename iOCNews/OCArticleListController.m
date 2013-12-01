//
//  SelectionController.m
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

#import "OCArticleListController.h"
#import "OCArticleCell.h"
#import "OCWebController.h"
#import "IIViewDeckController.h"
#import "NSString+HTML.h"
#import "UILabel+VerticalAlignment.h"
#import "AFNetworking.h"
#import "OCArticleImage.h"
#import "TSMessage.h"
#import "OCNewsHelper.h"
#import "Item.h"
#import "objc/runtime.h"
#import "UIImageView+OCWebCache.h"
#import "HexColor.h"

@interface OCArticleListController () {
    int currentIndex;
}

- (void) configureView;
- (void) scrollToTop;
- (void) previousArticle:(NSNotification*)n;
- (void) nextArticle:(NSNotification*)n;
- (void) articleChangeInFeed:(NSNotification*)n;
- (void) updateUnreadCount:(NSArray*)itemsToUpdate;
- (void) updatePredicate;
- (void) networkSuccess:(NSNotification*)n;
- (void) networkError:(NSNotification*)n;

@end

@implementation OCArticleListController

@synthesize markBarButtonItem;
@synthesize feedRefreshControl;
@synthesize feed = _feed;
@synthesize fetchedResultsController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Managing the detail item

- (void)setFeed:(Feed *)feed
{
    if (_feed != feed) {
        _feed = feed;

        [self configureView];
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (!fetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:NO];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        [fetchRequest setFetchBatchSize:20];
        
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                       managedObjectContext:[OCNewsHelper sharedHelper].context sectionNameKeyPath:nil
                                                                                  cacheName:@"ArticleCache"];
        
    }
    return fetchedResultsController;
}

- (void)configureView
{
    // Update the user interface for the detail item.
    self.navigationItem.title = self.feed.extra.displayTitle; // [self.feed objectForKey:@"title"];
    if (self.feed.myIdValue > -2) {
        self.refreshControl = self.feedRefreshControl;
    } else {
        self.refreshControl = nil;
    }
    [self updatePredicate];
    [self scrollToTop];
}

- (void) scrollToTop {
    self.markBarButtonItem.enabled = (self.feed.unreadCountValue > 0);
    if ([[self.fetchedResultsController fetchedObjects] count] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) refresh {
    [self.tableView reloadData];
    int unreadCount = self.feed.unreadCountValue;
    self.markBarButtonItem.enabled = (unreadCount > 0);    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.markBarButtonItem;
    self.markBarButtonItem.enabled = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"OCArticleCell" bundle:nil] forCellReuseIdentifier:@"ArticleCell"];
    self.tableView.rowHeight = 154;
    self.tableView.scrollsToTop = NO;

    IIViewDeckController *deckController = (IIViewDeckController*)self.viewDeckController.viewDeckController;
    UINavigationController *navController = (UINavigationController*)deckController.centerController;
    self.detailViewController = (OCWebController*)navController.topViewController;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previousArticle:) name:@"LeftTapZone" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextArticle:) name:@"RightTapZone" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleChangeInFeed:) name:@"ArticleChangeInFeed" object:nil];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"HideRead"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"ShowThumbnails"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self.tableView reloadData];
                                                  }];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.fetchedResultsController = nil;
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"HideRead"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id  sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UIFont*) makeItalic:(UIFont*)font {
    UIFontDescriptor *desc = font.fontDescriptor;
    UIFontDescriptor *italic = [desc fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    return [UIFont fontWithDescriptor:italic size:0.0f];
}

- (UIFont*) makeSmaller:(UIFont*)font {
    UIFontDescriptor *desc = font.fontDescriptor;
    UIFontDescriptor *italic = [desc fontDescriptorWithSize:desc.pointSize - 1];
    return [UIFont fontWithDescriptor:italic size:0.0f];
}

- (void)configureCell:(OCArticleCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.dateLabel.font = [self makeItalic:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    cell.summaryLabel.font = [self makeSmaller:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];

    cell.titleLabel.text = [item.title stringByConvertingHTMLToPlainText];
    [cell.titleLabel setTextVerticalAlignment:UITextVerticalAlignmentTop];
    NSString *dateLabelText = @"";
    NSString *author = item.author;
    if (![author isKindOfClass:[NSNull class]]) {
        
        if (author.length > 0) {
            const int clipLength = 50;
            if([author length] > clipLength) {
                dateLabelText = [NSString stringWithFormat:@"%@...",[author substringToIndex:clipLength]];
            } else {
                dateLabelText = author;
            }
        }
    }
    NSNumber *dateNumber = item.pubDate;
    if (![dateNumber isKindOfClass:[NSNull class]]) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
        if (date) {
            if (dateLabelText.length > 0) {
                dateLabelText = [dateLabelText stringByAppendingString:@" on "];
            }
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateStyle = NSDateFormatterMediumStyle;
            dateFormat.timeStyle = NSDateFormatterShortStyle;
            dateLabelText = [dateLabelText stringByAppendingString:[dateFormat stringFromDate:date]];
        }
    }
    cell.dateLabel.text = dateLabelText;
    
    NSString *summary = item.body;
    if ([summary rangeOfString:@"<style>" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        if ([summary rangeOfString:@"</style>" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSRange r;
            r.location = [summary rangeOfString:@"<style>" options:NSCaseInsensitiveSearch].location;
            r.length = [summary rangeOfString:@"</style>" options:NSCaseInsensitiveSearch].location - r.location + 8;
            NSString *sub = [summary substringWithRange:r];
            summary = [summary stringByReplacingOccurrencesOfString:sub withString:@""];
        }
    }
    cell.summaryLabel.text = [summary stringByConvertingHTMLToPlainText];
    [cell.summaryLabel setTextVerticalAlignment:UITextVerticalAlignmentTop];
    NSNumber *read = item.unread;
    if ([read intValue] == 1) {
        cell.summaryLabel.textColor = [UIColor darkTextColor];
        cell.titleLabel.textColor = [UIColor darkTextColor];
        cell.dateLabel.textColor = [UIColor darkTextColor];
        cell.articleImage.alpha = 1.0f;
    } else {
        cell.summaryLabel.textColor = [UIColor colorWithHexString:@"#696969"];
        cell.titleLabel.textColor = [UIColor colorWithHexString:@"#696969"];
        cell.dateLabel.textColor = [UIColor colorWithHexString:@"#696969"];
        cell.articleImage.alpha = 0.4f;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"]) {
        [cell.articleImage setRoundedImageWithURL:[NSURL URLWithString:[OCArticleImage findImage:summary]]];
    } else {
        [cell.articleImage setImage:nil];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OCArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArticleCell"];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentIndex = indexPath.row;
    Item *selectedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.detailViewController.item = selectedItem;
    [self.viewDeckController closeLeftView];
    if (selectedItem.unreadValue) {
        selectedItem.unreadValue = NO;
        [self updateUnreadCount:[NSArray arrayWithObject:selectedItem.myId]];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //NSLog(@"We have scrolled");
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self markRowsRead];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self markRowsRead];
}


#pragma mark - Actions

- (IBAction)doRefresh:(id)sender {
    if (self.feed) {
        [[OCNewsHelper sharedHelper] updateFeedWithId:self.feed.myId];
    }
}

- (IBAction)doMarkRead:(id)sender {
    if (self.feed.unreadCountValue > 0) {
        if ([self.fetchedResultsController fetchedObjects].count > 0) {
            NSMutableArray *idsToMarkRead = [NSMutableArray new];
            
            [[self.fetchedResultsController fetchedObjects] enumerateObjectsUsingBlock:^(Item *item, NSUInteger idx, BOOL *stop) {
                if (item.unreadValue) {
                    item.unreadValue = NO;
                    [idsToMarkRead addObject:item.myId];
                }
            }];
            [self updateUnreadCount:idsToMarkRead];
            self.markBarButtonItem.enabled = NO;
        }
    }
}

- (void) markRowsRead {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MarkWhileScrolling"]) {
        int unreadCount = self.feed.unreadCountValue;
        
        if (unreadCount > 0) {
            NSArray * vCells = self.tableView.indexPathsForVisibleRows;
            __block int row = 0;
            
            if (vCells.count > 0) {
                NSIndexPath *topCell = [vCells objectAtIndex:0];
                row = topCell.row;
                if (row > 0) {
                    --row;
                }
            }
            
            if ([self.fetchedResultsController fetchedObjects].count > 0) {
                NSMutableArray *idsToMarkRead = [NSMutableArray new];
                
                [[self.fetchedResultsController fetchedObjects] enumerateObjectsUsingBlock:^(Item *item, NSUInteger idx, BOOL *stop) {
                    if (idx >= row) {
                        *stop = YES;
                    }
                    if (item.unreadValue) {
                        item.unreadValue = NO;
                        [idsToMarkRead addObject:item.myId];
                    }
                }];
                
                unreadCount = unreadCount - [idsToMarkRead count];
                [self updateUnreadCount:idsToMarkRead];
                self.markBarButtonItem.enabled = (unreadCount > 0);
            }
        }
    }
}

- (void) updateUnreadCount:(NSArray *)itemsToUpdate {
    [[OCNewsHelper sharedHelper] markItemsReadOffline:itemsToUpdate];
    [self.tableView reloadData];
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
    if([keyPath isEqual:@"HideRead"]) {
        [self updatePredicate];
    }
    if([keyPath isEqual:@"ShowThumbnails"]) {
        [self.tableView reloadData];
    }
}

- (void)updatePredicate {
    NSError *error;
    NSPredicate *fetchPredicate;
    if (self.feed.myIdValue == -1) {
        fetchPredicate = [NSPredicate predicateWithFormat:@"starred == 1"];
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"]) {
            if (self.feed.myIdValue == -2) {
                fetchPredicate = [NSPredicate predicateWithFormat:@"unread == 1"];
            } else {
                NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"feedId == %@", self.feed.myId];
                NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"unread == 1"];
                NSArray *predArray = @[pred1, pred2];
                fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
            }
            self.fetchedResultsController.delegate = nil;
        } else {
            if (self.feed.myIdValue == -2) {
                fetchPredicate = nil;
            } else {
                NSLog(@"Feed Id: %@", self.feed.myId);
                fetchPredicate = [NSPredicate predicateWithFormat:@"feedId == %@", self.feed.myId];
            }
            self.fetchedResultsController.delegate = self;
        }
    }
    [NSFetchedResultsController deleteCacheWithName:@"ArticleCache"];
    self.fetchedResultsController.fetchRequest.predicate = fetchPredicate;
    
    if (![self.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    NSLog(@"Fetch Count: %d", self.fetchedResultsController.fetchedObjects.count);
    
    [self.tableView reloadData];
}

#pragma mark - Toolbar buttons

- (UIBarButtonItem *)markBarButtonItem {
    if (!markBarButtonItem) {
        markBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mark"] style:UIBarButtonItemStylePlain target:self action:@selector(doMarkRead:)];
        markBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return markBarButtonItem;
}

#pragma mark - Tap navigation

- (void) previousArticle:(NSNotification *)n {
    if (currentIndex != 0) {
        --currentIndex;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
    }
}

- (void) nextArticle:(NSNotification *)n {
    if (currentIndex < ([self.tableView numberOfRowsInSection:0] - 1)) {
        ++currentIndex;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
    }
}

- (void) articleChangeInFeed:(NSNotification *)n {
/*    NSString * articleText = [n.userInfo objectForKey:@"ArticleText"];
    FDArticle *a = (FDArticle*)[self.articles objectAtIndex:currentIndex];
    a.readable = articleText;

    BOOL success = [self.feed writeToFile];
    if (success) {
        [self configureView];
    } */
}

- (UIRefreshControl *)feedRefreshControl {
    if (!feedRefreshControl) {
        feedRefreshControl = [[UIRefreshControl alloc] init];
        [feedRefreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    }
    
    return feedRefreshControl;
}

- (void) networkSuccess:(NSNotification *)n {
    [self.refreshControl endRefreshing];
}

- (void)networkError:(NSNotification *)n {
    [self.refreshControl endRefreshing];
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(OCArticleCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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
