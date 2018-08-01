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
#import "ArticleListCell.h"
#import "OCWebController.h"
#import "NSString+HTML.h"
#import <AFNetworking/AFNetworking.h>
#import "OCArticleImage.h"
#import "RMessage.h"
#import "OCNewsHelper.h"
#import "Item.h"
#import "objc/runtime.h"
#import "UIImageView+OCWebCache.h"
#import "iOCNews-Swift.h"
#import "PHThemeManager.h"
#import "UIColor+PHColor.h"

@interface OCArticleListController () <UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, SCPageViewControllerDataSource, SCPageViewControllerDelegate> {
    long currentIndex;
    BOOL markingAllItemsRead;
    BOOL hideRead;
    NSArray *fetchedItems;
    BOOL aboutToFetch;
    CGFloat cellContentWidth;
}

@property (strong, nonatomic) IBOutlet UIScreenEdgePanGestureRecognizer *sideGestureRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *markGesture;
@property (nonatomic, strong, readonly) ArticleManagerController *articleManagerController;

- (void) configureView;
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
@synthesize markGesture;
@synthesize folderId;
@synthesize articleManagerController;

static NSString * const reuseIdentifier = @"ArticleCell";

#pragma mark - Managing the detail item

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
            __block long unreadCount = [self unreadCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                self.markBarButtonItem.enabled = (unreadCount > 0);
            });
        } else {
            fetchedItems = [NSArray new];
        }
    }
    @catch (NSException *exception) {
        self.navigationItem.title = self.feed.title;
    }
    @finally {
        if (self.feed.myIdValue > -2) {
            self.collectionView.refreshControl = self.feedRefreshControl;
        } else {
            self.collectionView.refreshControl = nil;
        }
        [self refresh];
        if (fetchedItems.count > 0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        self.collectionView.scrollsToTop = YES;
    }
}

- (void) refresh {
    long unreadCount = [self unreadCount];
    [self.collectionView reloadData];
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
    [self.collectionView registerNib:[UINib nibWithNibName:@"ArticleListCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.scrollsToTop = NO;
    [self.collectionView addGestureRecognizer:self.markGesture];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView addGestureRecognizer:self.sideGestureRecognizer];
//    self.tableView.tableFooterView = [UIView new];
    
    markingAllItemsRead = NO;
    aboutToFetch = NO;
    cellContentWidth = 700;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkCompleted:) name:@"NetworkCompleted" object:nil];
    
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self.collectionView reloadData];
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
        [self.collectionView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configureView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSLog(@"My width = %f", size.width);
        [self willUpdateToDisplayMode: self.splitViewController.displayMode];
    }
}

- (void)willUpdateToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
        if (displayMode == UISplitViewControllerDisplayModeAllVisible) {
            cellContentWidth = ((screenWidth / 3) * 2) - 50;
            [self.collectionView reloadData];
        } else if (displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
            cellContentWidth = MIN(700, screenWidth  - 100);
            [self.collectionView reloadData];
        }
    }
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

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
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

- (void)configureCell:(ArticleListCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    @try {
        Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        cell.mainCellViewWidthContraint.constant = cellContentWidth;
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
                    dispatch_main_async_safe(^{
                        [cell.articleImage setRoundedImageWithURL:[NSURL URLWithString:urlString]];
                        cell.articleImage.hidden = NO;
                        cell.thumbnailContainerWidthConstraint.constant = cell.articleImage.frame.size.width;
                        cell.articleImageWidthConstraint.constant = cell.articleImage.frame.size.width;
                        cell.contentContainerLeadingConstraint.constant = cell.articleImage.frame.size.width;
                    });
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect bounds = [UIScreen mainScreen].bounds;
    if (indexPath.section == 0) {
        return CGSizeMake(bounds.size.width, 154.0);
    } else {
        return CGSizeZero;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ArticleListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ArticleCell" forIndexPath:indexPath];
    cell.tag = indexPath.row;
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


#pragma mark - Table view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    currentIndex = indexPath.row;
    Item *selectedItem = [fetchedItems objectAtIndex: currentIndex];
    if (selectedItem && selectedItem.myId) {
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:self.articleManagerController animated:YES];
        [self.articleManagerController navigateToPageAtIndex:currentIndex animated:NO completion:nil];
        if (selectedItem.unreadValue) {
            selectedItem.unreadValue = NO;
            [self updateUnreadCount:@[selectedItem.myId]];
        }
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
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
        if (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
            NSLog(@"Display Mode: %ld", (long)self.splitViewController.displayMode);
            if (self.splitViewController.displayMode != UISplitViewControllerDisplayModePrimaryHidden) {
                result = NO;
            }
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
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        [self.navigationController.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                } else {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                }
            } else {
                if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                } else {
                    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
                }
            }
        }];
    }
}

- (void) markRowsRead {
    @try {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MarkWhileScrolling"]) {
            __block long unreadCount = [self unreadCount];
            
            if (unreadCount > 0) {
                NSArray * vCells = self.collectionView.indexPathsForVisibleItems;
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
                    dispatch_main_async_safe(^{
                        self.markBarButtonItem.enabled = (unreadCount > 0);
                    });
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

- (ArticleManagerController *)articleManagerController {
    if (!articleManagerController) {
        articleManagerController = [self.storyboard instantiateViewControllerWithIdentifier:@"ArticleManagerController"];
        articleManagerController.dataSource = self;
        articleManagerController.delegate = self;
        [articleManagerController setLayouter:[SCPageLayouter new] animated:NO completion:nil];
    }
    return articleManagerController;
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
        
        CGPoint p = [gestureRecognizer locationInView:self.collectionView];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
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
    self.collectionView.scrollsToTop = NO;
}

- (void)drawerClosed:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkError:) name:@"NetworkError" object:nil];
    self.collectionView.scrollsToTop = YES;
}

- (void) networkCompleted:(NSNotification *)n {
    [self.collectionView.refreshControl endRefreshing];
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
//    [self.collectionView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UICollectionView *collectionView = self.collectionView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(ArticleListCell*)[collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            [collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]];
            break;
    }
}

/*
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
*/

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
//    [self.collectionView endUpdates];
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
    if ([self.sideGestureRecognizer translationInView:self.collectionView].x > 10) {
        [UIView animateWithDuration:0.3 animations:^{
            self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        } completion: nil];
    }
}

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController {
    return fetchedItems.count;
}

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex {
    OCWebController *webController = [self.storyboard instantiateViewControllerWithIdentifier:@"WebController"];
    webController.itemIndex = pageIndex;
    Item *currentItem = [fetchedItems objectAtIndex:pageIndex];
    webController.item = currentItem;
    return webController;
    
//    if let webController = self.storyboard?.instantiateViewController(withIdentifier: "WebController") as? OCWebController {
//        webController.itemIndex = UInt(pageIndex)
//        let currentItem = self.articles[Int(pageIndex)]
//        webController.item = currentItem
//        if currentItem.unreadValue == true {
//            currentItem.unreadValue = false
//            let set = Set<NSNumber>([currentItem.myId])
//            OCNewsHelper.shared().markItemsReadOffline(NSMutableSet(set: set))
//        }
//        return webController
//        

}

- (NSUInteger)initialPageInPageViewController:(SCPageViewController *)pageViewController {
    return currentIndex;
}

@end
