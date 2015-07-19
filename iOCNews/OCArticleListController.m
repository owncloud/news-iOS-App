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
#import "NSString+HTML.h"
#import "UILabel+VerticalAlignment.h"
#import "AFNetworking.h"
#import "OCArticleImage.h"
#import "TSMessage.h"
#import "OCNewsHelper.h"
#import "Item.h"
#import "objc/runtime.h"
#import "UIViewController+MMDrawerController.h"
#import "UIImageView+AFNetworking.h"
#import "OCRoundedImageResponseSerializer.h"

@interface OCArticleListController () <UIGestureRecognizerDelegate> {
    long currentIndex;
    BOOL markingAllItemsRead;
}

@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *markGesture;

- (void) configureView;
- (void) scrollToTop;
- (void) previousArticle:(NSNotification*)n;
- (void) nextArticle:(NSNotification*)n;
- (void) updateUnreadCount:(NSArray*)itemsToUpdate;
- (void) networkCompleted:(NSNotification*)n;
- (void) networkError:(NSNotification*)n;
- (IBAction)handleCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer;
- (NSInteger) unreadCount;

@end

@implementation OCArticleListController

@synthesize markBarButtonItem;
@synthesize menuBarButtonItem;
@synthesize feedRefreshControl;
@synthesize feed = _feed;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize markGesture;
@synthesize folderId;

#pragma mark - Managing the detail item

- (void)setFeed:(Feed *)feed {
    _feed = feed;
    [self configureView];
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:[OCNewsHelper sharedHelper].context];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:NO];
        fetchRequest.sortDescriptors = @[sort];
        fetchRequest.fetchBatchSize = 25;
        
        NSError *error;
        NSPredicate *fetchPredicate;
        if (self.feed.myIdValue == -1) {
            fetchPredicate = [NSPredicate predicateWithFormat:@"starred == 1"];
            fetchRequest.fetchLimit = self.feed.unreadCountValue;
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"]) {
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
                        fetchRequest.fetchLimit = fetchLimit;
                    } else {
                        fetchPredicate = [NSPredicate predicateWithFormat:@"unread == 1"];
                    }
                } else {
                    NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"feedId == %@", self.feed.myId];
                    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"unread == 1"];
                    NSArray *predArray = @[pred1, pred2];
                    fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
                    fetchRequest.fetchLimit = self.feed.articleCountValue;
                }
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
                        fetchRequest.fetchLimit = fetchLimit;
                    } else {
                        fetchPredicate = nil;
                        fetchRequest.fetchLimit = self.feed.articleCountValue;
                    }
                } else {
                    fetchPredicate = [NSPredicate predicateWithFormat:@"feedId == %@", self.feed.myId];
                    fetchRequest.fetchLimit = self.feed.articleCountValue;
                }
            }
        }
        fetchRequest.predicate = fetchPredicate;
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                managedObjectContext:[OCNewsHelper sharedHelper].context
                                                                  sectionNameKeyPath:nil
                                                                           cacheName:nil];
        _fetchedResultsController.delegate = self;
        if (![_fetchedResultsController performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
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
    }
}

- (void) scrollToTop {
    self.markBarButtonItem.enabled = ([self unreadCount] > 0);
    if ([[self.fetchedResultsController fetchedObjects] count] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) refresh {
    self.fetchedResultsController = nil;
    long unreadCount = [self unreadCount];
    [self.tableView reloadData];
    self.markBarButtonItem.enabled = (unreadCount > 0);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    CALayer *border = [CALayer layer];
    border.backgroundColor = [UIColor lightGrayColor].CGColor;
    border.frame = CGRectMake(0, 0, 1, 1024);
    [self.mm_drawerController.centerViewController.view.layer addSublayer:border];

    self.navigationItem.leftBarButtonItem = self.menuBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.markBarButtonItem;
    self.markBarButtonItem.enabled = NO;
    self.folderId = 0;
    [self.tableView registerNib:[UINib nibWithNibName:@"OCArticleCell" bundle:nil] forCellReuseIdentifier:@"ArticleCell"];
    self.tableView.rowHeight = 154;
    self.tableView.scrollsToTop = NO;
    [self.tableView addGestureRecognizer:self.markGesture];

    UINavigationController *navController = (UINavigationController*)self.mm_drawerController.mm_drawerController.centerViewController;
    self.detailViewController = (OCWebController*)navController.topViewController;
    
    markingAllItemsRead = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previousArticle:) name:@"LeftTapZone" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextArticle:) name:@"RightTapZone" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleChangeInFeed:) name:@"ArticleChangeInFeed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkCompleted:) name:@"NetworkCompleted" object:nil];
    
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
}

- (void)contextSaved:(NSNotification*)notification {
    if (markingAllItemsRead) {
        markingAllItemsRead = NO;
        [self refresh];
    }
}

- (void)dealloc
{
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
    @try {
        Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        cell.dateLabel.font = [self makeItalic:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
        cell.summaryLabel.font = [self makeSmaller:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
        
        cell.titleLabel.preferredMaxLayoutWidth = 320.0f;
        cell.titleLabel.text = [item.title stringByConvertingHTMLToPlainText];
        [cell.titleLabel setTextVerticalAlignment:UITextVerticalAlignmentTop];
        NSString *dateLabelText = @"";
        
        NSNumber *dateNumber = item.pubDate;
        if (![dateNumber isKindOfClass:[NSNull class]]) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
            if (date) {
                NSLocale *currentLocale = [NSLocale currentLocale];
                NSString *dateComponents = @"MMM d";
                NSString *dateFormatString = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:currentLocale];
//                NSLog(@"Date format for %@: %@", [currentLocale displayNameForKey:NSLocaleIdentifier value:[currentLocale localeIdentifier]], dateFormatString);
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
                NSString *faviconLink = feed.faviconLink;
                if ([faviconLink hasPrefix:@"http"]) {
                    NSURL *faviconURL = [NSURL URLWithString:faviconLink] ;
                    if (faviconURL) {
                        if (cell.tag == indexPath.row) {
                            [cell.favIconImage setImageWithURL:faviconURL placeholderImage:[UIImage imageNamed:@"favicon"]];
                        }
                    }
                } else {
                    if (faviconLink && faviconLink.length > 0) {
                        [cell.favIconImage setImage:[UIImage imageNamed:faviconLink]];
                    }
                }
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
        [cell.summaryLabel setTextVerticalAlignment:UITextVerticalAlignmentTop];
        cell.starImage.image = nil;
        if (item.starredValue) {
            cell.starImage.image = [UIImage imageNamed:@"star_icon"];
        }
        NSNumber *read = item.unread;
        if ([read intValue] == 1) {
            cell.summaryLabel.textColor = [UIColor darkTextColor];
            cell.titleLabel.textColor = [UIColor darkTextColor];
            cell.dateLabel.textColor = [UIColor darkTextColor];
            cell.articleImage.alpha = 1.0f;
            cell.favIconImage.alpha = 1.0f;
        } else {
            cell.summaryLabel.textColor = [UIColor colorWithWhite:0.41 alpha:1.0];
            cell.titleLabel.textColor = [UIColor colorWithWhite:0.41 alpha:1.0];
            cell.dateLabel.textColor = [UIColor colorWithWhite:0.41 alpha:1.0];
            cell.articleImage.alpha = 0.4f;
            cell.favIconImage.alpha = 0.4f;
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"]) {
            NSString *urlString = [OCArticleImage findImage:summary];
            if (urlString) {
                if (cell.tag == indexPath.row) {
                    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
                    cell.articleImage.imageResponseSerializer = [OCRoundedImageResponseSerializer serializerWithSize:cell.articleImage.bounds.size];
                    [cell.articleImage setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            cell.articleImage.image = image;
                            [cell setNeedsLayout];
                            [cell layoutIfNeeded];
                        });
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        cell.articleImage.image = nil;
                        [cell setNeedsLayout];
                        [cell layoutIfNeeded];
                    }];
                }
            } else {
                [cell.articleImage setImage:nil];
            }
        } else {
            [cell.articleImage setImage:nil];
        }
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
    }
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
    if (selectedItem) {
        self.detailViewController.item = selectedItem;
        [self.mm_drawerController.mm_drawerController closeDrawerAnimated:YES completion:nil];
        if (selectedItem.unreadValue) {
            selectedItem.unreadValue = NO;
            [self updateUnreadCount:@[selectedItem.myId]];
        }
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


#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    BOOL result = YES;
    if ([gestureRecognizer isEqual:self.markGesture]) {
        if (self.mm_drawerController.openSide != MMDrawerSideNone) {
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

- (IBAction)doMarkRead:(id)sender {
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
    [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)onMenu:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
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
                
                if ([self.fetchedResultsController fetchedObjects].count > 0) {
                    __block NSMutableArray *idsToMarkRead = [NSMutableArray new];
                    
                    [[self.fetchedResultsController fetchedObjects] enumerateObjectsUsingBlock:^(Item *item, NSUInteger idx, BOOL *stop) {
                        if (idx >= row) {
                            *stop = YES;
                        }
                        if (item) {
                            if (item.unreadValue) {
                                item.unreadValue = NO;
                                [idsToMarkRead addObject:item.myId];
                            }
                        }
                    }];
                    
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
        markBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mark"] style:UIBarButtonItemStylePlain target:self action:@selector(doMarkRead:)];
        markBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return markBarButtonItem;
}

- (UIBarButtonItem *)menuBarButtonItem {
    if (!menuBarButtonItem) {
        menuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sideMenu"] style:UIBarButtonItemStylePlain target:self action:@selector(onMenu:)];
        menuBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return menuBarButtonItem;
}

#pragma mark - Tap navigation

- (void) previousArticle:(NSNotification *)n {
    if ((currentIndex > 0) && (currentIndex < [self.tableView numberOfRowsInSection:0])) {
        --currentIndex;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
    }
}

- (void) nextArticle:(NSNotification *)n {
    if ((currentIndex >= 0) && (currentIndex < ([self.tableView numberOfRowsInSection:0] - 1))) {
        ++currentIndex;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
    }
}

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

@end
