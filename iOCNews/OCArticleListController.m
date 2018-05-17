//
//  SelectionController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2016 Peter Hedlund peter.hedlund@me.com
 
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
#import "NSString+HTML.h"
#import <AFNetworking/AFNetworking.h>
#import "OCArticleImage.h"
#import "RMessage.h"
#import "OCNewsHelper.h"
#import "Item.h"
#import "objc/runtime.h"
#import "UIImageView+OCWebCache.h"
#import "PHArticleManagerController.h"
#import "PHThemeManager.h"
#import "UIColor+PHColor.h"

@interface OCArticleListController () <UIGestureRecognizerDelegate> {
    long currentIndex;
    BOOL markingAllItemsRead;
    BOOL hideRead;
    NSArray *fetchedItems;
    BOOL aboutToFetch;
}

@property (strong, nonatomic) IBOutlet UIScreenEdgePanGestureRecognizer *sideGestureRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *markGesture;

- (void) configureView;
- (void) scrollToTop;
- (void) updateUnreadCount:(NSArray*)itemsToUpdate;
- (void) networkCompleted:(NSNotification*)n;
- (void) networkError:(NSNotification*)n;
- (IBAction)handleCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer;
- (NSInteger) unreadCount;

@end

@implementation OCArticleListController

@synthesize feedRefreshControl;
@synthesize markBarButtonItem;
@synthesize feed = _feed;
@synthesize fetchRequest = _fetchRequest;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize markGesture;
@synthesize folderId;

#pragma mark - Managing the detail item

- (void)setFeed:(Feed *)feed {
    _feed = feed;
    _fetchRequest = nil;
    _fetchedResultsController = nil;
    [self configureView];
}

- (NSFetchRequest *)fetchRequest {
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        _fetchRequest.entity = entity;
        _fetchRequest.fetchBatchSize = 25;
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:NO];
        _fetchRequest.sortDescriptors = @[sort];
    }
    return _fetchRequest;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController == nil) {
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                        managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        if (!aboutToFetch) {
            return _fetchedResultsController;
        }
        
        NSPredicate *fetchPredicate;
        if (self.feed.myIdValue == -1) {
            fetchPredicate = [NSPredicate predicateWithFormat:@"starred == 1"];
            self.fetchRequest.fetchLimit = self.feed.unreadCountValue;
        } else {
            if (hideRead) {
                if (self.feed.myIdValue == -2) {
                    if (self.folderId > 0) {
                        NSMutableArray *feedsArray = [NSMutableArray new];
                        NSArray *folderFeeds = [[OCNewsHelper sharedHelper] feedsInFolderWithId:[NSNumber numberWithInteger:self.folderId]];
                        __block NSInteger fetchLimit = 0;
                        [folderFeeds enumerateObjectsUsingBlock:^(Feed *feed, NSUInteger idx, BOOL *stop) {
                            [feedsArray addObject:[NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"feedId == %@", feed.myId], [NSPredicate predicateWithFormat:@"unread == 1"] ]]];
                            fetchLimit += feed.articleCountValue;
                        }];
                        fetchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:feedsArray];
                        _fetchedResultsController.fetchRequest.fetchLimit = fetchLimit;
                    } else {
                        fetchPredicate = [NSPredicate predicateWithFormat:@"unread == 1"];
                    }
                } else {
                    NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"feedId == %@", self.feed.myId];
                    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"unread == 1"];
                    NSArray *predArray = @[pred1, pred2];
                    fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
                    _fetchedResultsController.fetchRequest.fetchLimit = self.feed.articleCountValue;
                }
                _fetchedResultsController.delegate = nil;
            } else {
                if (self.feed.myIdValue == -2) {
                    if (self.folderId > 0) {
                        NSMutableArray *feedsArray = [NSMutableArray new];
                        NSArray *folderFeeds = [[OCNewsHelper sharedHelper] feedsInFolderWithId:[NSNumber numberWithInteger:self.folderId]];
                        __block NSInteger fetchLimit = 0;
                        [folderFeeds enumerateObjectsUsingBlock:^(Feed *feed, NSUInteger idx, BOOL *stop) {
                            [feedsArray addObject:[NSPredicate predicateWithFormat:@"feedId == %@", feed.myId]];
                            fetchLimit += feed.articleCountValue;
                        }];
                        fetchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:feedsArray];
                        _fetchedResultsController.fetchRequest.fetchLimit = fetchLimit;
                    } else {
                        fetchPredicate = nil;
                        _fetchedResultsController.fetchRequest.fetchLimit = self.feed.articleCountValue;
                    }
                } else {
                    fetchPredicate = [NSPredicate predicateWithFormat:@"feedId == %@", self.feed.myId];
                    _fetchedResultsController.fetchRequest.fetchLimit = self.feed.articleCountValue;
                }
                _fetchedResultsController.delegate = self;
            }
        }
        _fetchedResultsController.fetchRequest.predicate = fetchPredicate;
    }
    return _fetchedResultsController;
}

- (void)configureView
{
    // Update the user interface for the detail item.
    @try {
        if (self.feed.myIdValue == -2) {
            Folder *folder = [[OCNewsHelper sharedHelper] folderWithId:[NSNumber numberWithLong:self.folderId]];
            if (folder && folder.name.length) {
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                if ([prefs boolForKey:@"HideRead"]) {
                    self.navigationItem.title = [NSString stringWithFormat:@"All Unread %@ Articles", folder.name];
                } else {
                    self.navigationItem.title = [NSString stringWithFormat:@"All %@ Articles", folder.name];
                }
            } else {
                self.navigationItem.title = self.feed.title;
            }
        } else {
            self.navigationItem.title = self.feed.title;
        }
        hideRead = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"];
        aboutToFetch = YES;
        BOOL success = [self.fetchedResultsController performFetch:nil];
        aboutToFetch = NO;
        if (success) {
            fetchedItems = self.fetchedResultsController.fetchedObjects;
            long unreadCount = [self unreadCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
            self.markBarButtonItem.enabled = (unreadCount > 0);
        } else {
            fetchedItems = [NSArray new];
        }
    }
    @catch (NSException *exception) {
        self.navigationItem.title = self.feed.title;
    }
    @finally {
        if (self.feed.myIdValue > -2) {
            self.refreshControl = self.feedRefreshControl;
        } else {
            self.refreshControl = nil;
        }
        [self refresh];
        [self scrollToTop];
        self.tableView.scrollsToTop = YES;
    }
}

- (void) scrollToTop {
    self.markBarButtonItem.enabled = ([self unreadCount] > 0);
    if (fetchedItems.count > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) refresh {
    long unreadCount = [self unreadCount];
    [self.tableView reloadData];
    self.markBarButtonItem.enabled = (unreadCount > 0);
}

#pragma mark - View lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"HideRead"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"ShowThumbnails"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"ShowFavicons"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.rightBarButtonItem = self.markBarButtonItem;
    self.markBarButtonItem.enabled = NO;
    self.folderId = 0;
    [self.tableView registerNib:[UINib nibWithNibName:@"OCArticleCell" bundle:nil] forCellReuseIdentifier:@"ArticleCell"];
    self.tableView.scrollsToTop = NO;
    [self.tableView addGestureRecognizer:self.markGesture];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView addGestureRecognizer:self.sideGestureRecognizer];
    self.tableView.tableFooterView = [UIView new];

    markingAllItemsRead = NO;
    aboutToFetch = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkCompleted:) name:@"NetworkCompleted" object:nil];
    
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self.tableView reloadData];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerOpened:)
                                                 name:@"DrawerOpened"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerClosed:)
                                                 name:@"DrawerClosed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextSaved:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[OCNewsHelper sharedHelper].context];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ThemeUpdate" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self.tableView reloadData];
    }];
}

- (void)contextSaved:(NSNotification*)notification {
    if (markingAllItemsRead) {
        markingAllItemsRead = NO;
        hideRead = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"];
        aboutToFetch= YES;
        BOOL success = [self.fetchedResultsController performFetch:nil];
        aboutToFetch = NO;
        if (success) {
            fetchedItems = self.fetchedResultsController.fetchedObjects;
        }
        [self refresh];
    }
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"HideRead"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ShowThumbnails"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ShowFavicons"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.fetchedResultsController.delegate = nil;
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
    NSInteger result = 0;
    if (self.feed)
    {
        id  sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        result = [sectionInfo numberOfObjects];
    }
    return result;
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
    @try {
        Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];

        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        cell.dateLabel.font = [self makeItalic:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
        cell.summaryLabel.font = [self makeSmaller:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
        
        cell.titleLabel.text = [item.title stringByConvertingHTMLToPlainText];
        NSString *dateLabelText = @"";
        
        NSNumber *dateNumber = item.pubDate;
        if (![dateNumber isKindOfClass:[NSNull class]]) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
            if (date) {
                NSLocale *currentLocale = [NSLocale currentLocale];
                NSString *dateComponents = @"MMM d";
                NSString *dateFormatString = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:currentLocale];
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                dateFormat.dateFormat = dateFormatString;
                dateLabelText = [dateLabelText stringByAppendingString:[dateFormat stringFromDate:date]];
            }
        }
        if (dateLabelText.length > 0) {
            dateLabelText = [dateLabelText stringByAppendingString:@" | "];
        }
        
        NSString *author = item.author;
        if (![author isKindOfClass:[NSNull class]]) {
            
            if (author.length > 0) {
                const int clipLength = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 50 : 25;
                if([author length] > clipLength) {
                    dateLabelText = [dateLabelText stringByAppendingString:[NSString stringWithFormat:@"%@...",[author substringToIndex:clipLength]]];
                } else {
                    dateLabelText = [dateLabelText stringByAppendingString:author];
                }
            }
        }
        Feed *feed = [[OCNewsHelper sharedHelper] feedWithId:item.feedId];
        if (feed) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowFavicons"]) {
                if (cell.tag == indexPath.row) {
                    [[OCNewsHelper sharedHelper] faviconForFeedWithId:feed.myId imageView: cell.favIconImage];
                    cell.favIconImage.hidden = NO;
                    cell.dateLabelLeadingConstraint.constant = 21;
                }
            }
            else {
                cell.favIconImage.hidden = YES;
                cell.dateLabelLeadingConstraint.constant = 0.0;
            }
            
            if (feed.title && ![feed.title isEqualToString:author]) {
                if (author.length > 0) {
                    dateLabelText = [dateLabelText stringByAppendingString:@" | "];
                }
                dateLabelText = [dateLabelText stringByAppendingString:feed.title];
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
        cell.starImage.image = nil;
        if (item.starredValue) {
            cell.starImage.image = [UIImage imageNamed:@"star_icon"];
        }
        NSNumber *read = item.unread;
        if ([read boolValue] == YES) {
            [cell.summaryLabel setThemeTextColor:PHThemeManager.sharedManager.unreadTextColor];
            [cell.titleLabel setThemeTextColor:PHThemeManager.sharedManager.unreadTextColor];
            [cell.dateLabel setThemeTextColor:PHThemeManager.sharedManager.unreadTextColor];
            cell.articleImage.alpha = 1.0f;
            cell.favIconImage.alpha = 1.0f;
        } else {
            [cell.summaryLabel setThemeTextColor:[UIColor readTextColor]];
            [cell.titleLabel setThemeTextColor:[UIColor readTextColor]];
            [cell.dateLabel setThemeTextColor:[UIColor readTextColor]];
            cell.articleImage.alpha = 0.4f;
            cell.favIconImage.alpha = 0.4f;
        }
        cell.summaryLabel.highlightedTextColor = cell.summaryLabel.textColor;
        cell.titleLabel.highlightedTextColor = cell.titleLabel.textColor;
        cell.dateLabel.highlightedTextColor = cell.dateLabel.textColor;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"]) {
            NSString *urlString = [OCArticleImage findImage:summary];
            if (urlString) {
                if (cell.tag == indexPath.row) {
                    [cell.articleImage setRoundedImageWithURL:[NSURL URLWithString:urlString]];
                    cell.articleImage.hidden = NO;
                    cell.thumbnailContainerWidthConstraint.constant = cell.articleImage.frame.size.width;
                    cell.articleImageWidthConstraint.constant = cell.articleImage.frame.size.width;
                    cell.contentContainerLeadingConstraint.constant = cell.articleImage.frame.size.width;
                }
            } else {
                cell.articleImage.hidden = YES;
                cell.thumbnailContainerWidthConstraint.constant = 0.0;
                cell.articleImageWidthConstraint.constant = 0.0;
                cell.contentContainerLeadingConstraint.constant = 0.0;
            }
        } else {
            cell.articleImage.hidden = YES;
            cell.thumbnailContainerWidthConstraint.constant = 0.0;
            cell.articleImageWidthConstraint.constant = 0.0;
            cell.contentContainerLeadingConstraint.constant = 0.0;
        }
        cell.highlighted = NO;
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 154.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OCArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArticleCell"];
    cell.tag = indexPath.row;
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentIndex = indexPath.row;
    Item *selectedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (selectedItem && selectedItem.myId) {
        PHArticleManagerController *articleManagerController = [self.storyboard instantiateViewControllerWithIdentifier:@"ArticleManagerController"];
        articleManagerController.articles = fetchedItems;
        articleManagerController.articleIndex = currentIndex;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:articleManagerController animated:YES];
        if (selectedItem.unreadValue) {
            selectedItem.unreadValue = NO;
            [self updateUnreadCount:@[selectedItem.myId]];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //NSLog(@"We have scrolled");
    hideRead = false;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self markRowsRead];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self markRowsRead];
}


#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    BOOL result = YES;
    if ([gestureRecognizer isEqual:self.markGesture]) {
        if (self.splitViewController.displayMode != UISplitViewControllerDisplayModePrimaryHidden) {
            result = NO;
        }
    }
    return result;
}

#pragma mark - Actions

- (IBAction)doRefresh:(id)sender {
    if (self.feed) {
        [[OCNewsHelper sharedHelper] updateFeedWithId:self.feed.myId];
    }
}

- (IBAction)onMarkRead:(id)sender {
    markingAllItemsRead = YES;

    if (self.folderId > 0) {
        [[OCNewsHelper sharedHelper] markAllItemsRead:OCUpdateTypeFolder feedOrFolderId:@(self.folderId)];
    } else {
        if (self.feed.myIdValue == -2) {
            [[OCNewsHelper sharedHelper] markAllItemsRead:OCUpdateTypeAll feedOrFolderId:nil];
        } else {
            [[OCNewsHelper sharedHelper] markAllItemsRead:OCUpdateTypeFeed feedOrFolderId:self.feed.myId];
        }
    }
    self.markBarButtonItem.enabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
    }];
}

- (void) markRowsRead {
    @try {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MarkWhileScrolling"]) {
            long unreadCount = [self unreadCount];
            
            if (unreadCount > 0) {
                NSArray * vCells = self.tableView.indexPathsForVisibleRows;
                __block long row = 0;
                
                if (vCells.count > 0) {
                    NSIndexPath *topCell = [vCells objectAtIndex:0];
                    row = topCell.row;
                    if (row > 0) {
                        --row;
                    }
                }
                
                if (fetchedItems.count > 0) {
                    NSMutableArray *idsToMarkRead = [NSMutableArray new];
                    NSInteger index = 0;
                    for (Item *item in fetchedItems) {
                        if (index > row) {
                            break;
                        }
                        if (item.unreadValue) {
                            item.unreadValue = NO;
                            [idsToMarkRead addObject:item.myId];
                        }
                        index += 1;
                    }
                    
                    unreadCount = unreadCount - [idsToMarkRead count];
                    [self updateUnreadCount:idsToMarkRead];
                    self.markBarButtonItem.enabled = (unreadCount > 0);
                }
            }
        }
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
    }
}

- (void)updateUnreadCount:(NSArray *)itemsToUpdate {
    [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithArray:itemsToUpdate]];
    [self refresh];
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
    if([keyPath isEqual:@"HideRead"]) {
        [self refresh];
    }
    if([keyPath isEqual:@"ShowThumbnails"] || [keyPath isEqual:@"ShowFavicons"]) {
        [self refresh];
    }
}

#pragma mark - Toolbar buttons

- (UIBarButtonItem *)markBarButtonItem {
    if (!markBarButtonItem) {
        markBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mark"] style:UIBarButtonItemStylePlain target:self action:@selector(onMarkRead:)];
        markBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return markBarButtonItem;
}

#pragma mark - Tap navigation

- (UISwipeGestureRecognizer *) markGesture {
    if (!markGesture) {
        markGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellSwipe:)];
        markGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        markGesture.delegate = self;
    }
    return markGesture;
}

- (IBAction)handleCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    //http://stackoverflow.com/a/14364085/2036378 (why it's sometimes a good idea to retrieve the cell)
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath == nil) {
//            NSLog(@"swipe on table view but not on a row");
        } else {
            if (indexPath.section == 0) {
                @try {
                    Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    if (item && item.myId) {
                        if (item.unreadValue) {
                            item.unreadValue = NO;
                            [self updateUnreadCount:@[item.myId]];
                        } else {
                            if (item.starredValue) {
                                item.starredValue = NO;
                                [[OCNewsHelper sharedHelper] unstarItemOffline:item.myId];
                            } else {
                                item.starredValue = YES;
                                [[OCNewsHelper sharedHelper] starItemOffline:item.myId];
                            }
                        }
                    }
                }
                @catch (NSException *exception) {
                    //
                }
                @finally {
                    //
                }
                //}
            }
        }
    }
}

- (UIRefreshControl *)feedRefreshControl {
    if (!feedRefreshControl) {
        feedRefreshControl = [[UIRefreshControl alloc] init];
        [feedRefreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    }
    
    return feedRefreshControl;
}

- (void)drawerOpened:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NetworkError" object:nil];
    self.tableView.scrollsToTop = NO;
}

- (void)drawerClosed:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkError:) name:@"NetworkError" object:nil];
    self.tableView.scrollsToTop = YES;
}

- (void) networkCompleted:(NSNotification *)n {
    [self.refreshControl endRefreshing];
}

- (void)networkError:(NSNotification *)n {
    [RMessage showNotificationInViewController:self.navigationController
                                         title:[n.userInfo objectForKey:@"Title"]
                                      subtitle:[n.userInfo objectForKey:@"Message"]
                                     iconImage:nil
                                          type:RMessageTypeError
                                customTypeName:nil
                                      duration:RMessageDurationEndless
                                      callback:nil
                                   buttonTitle:nil
                                buttonCallback:nil
                                    atPosition:RMessagePositionTop
                          canBeDismissedByUser:YES];
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
        default:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
    self.markBarButtonItem.enabled = ([self unreadCount] > 0);
}

- (NSInteger)unreadCount {
    NSInteger result = 0;
    if (self.feed) {
        if ((self.feed.myIdValue == -2) && (self.folderId > 0)) {
            Folder *folder = [[OCNewsHelper sharedHelper] folderWithId:[NSNumber numberWithLong:self.folderId]];
            result = folder.unreadCountValue;
        } else {
            result = self.feed.unreadCountValue;
        }
    }
    return result;
}


- (IBAction)onSideGestureRecognizer:(id)sender {
    if ([self.sideGestureRecognizer translationInView:self.tableView].x > 10) {
        [UIView animateWithDuration:0.3 animations:^{
            self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
        } completion: nil];
    }
}

@end
