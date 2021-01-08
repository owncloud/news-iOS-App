//
//  SelectionController.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2019 Peter Hedlund peter.hedlund@me.com
 
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

#import "ArticleListController.h"
#import "NSString+HTML.h"
#import "OCArticleImage.h"
#import "iOCNews-Swift.h"
#import "OCNewsHelper.h"
#import "Item+CoreDataClass.h"
#import "PHThemeManager.h"
#import "UIColor+PHColor.h"
#import "ArticleController.h"
#import "iOCNews-Swift.h"
#import "UICollectionView+ValidIndexPath.h"
@import AFNetworking;

@interface ArticleListController () <UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching> {
    BOOL markingAllItemsRead;
    NSArray *fetchedItems;
    BOOL comingFromDetail;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *markBarButtonItem;
@property (strong, nonatomic) IBOutlet UIScreenEdgePanGestureRecognizer *sideGestureRecognizer;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *markGesture;

@property (strong, nonatomic) NSOperationQueue *itemProviderOperationQueue;
@property (strong, nonatomic) NSMutableDictionary<NSIndexPath *, NSBlockOperation *> *operations;
@property (strong, nonatomic) NSMutableDictionary<NSIndexPath *, ItemProvider *> *fetchedItemProviders;


- (void) configureView;
- (void) networkCompleted:(NSNotification*)n;
- (void) networkError:(NSNotification*)n;
- (IBAction)handleCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer;
- (NSInteger) unreadCount;

@end

@implementation ArticleListController

@synthesize feedRefreshControl;
@synthesize feed = _feed;
@synthesize markGesture;

static NSString * const reuseIdentifier = @"ArticleCell";

#pragma mark - Managing the detail item

- (void)configureView
{
    // Update the user interface for the detail item.
    @try {
        if (self.feed.myId == -2) {
            Folder *folder = [[OCNewsHelper sharedHelper] folderWithId:self.folderId];
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
        self.aboutToFetch = YES;
        BOOL success = [self.fetchedResultsController performFetch:nil];
        self.aboutToFetch = NO;
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
        if (self.feed.myId > -2) {
            self.collectionView.refreshControl = self.feedRefreshControl;
        } else {
            self.collectionView.refreshControl = nil;
        }
        [self refresh];
        if (comingFromDetail == NO) {
            if (fetchedItems.count > 0) {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            }
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

- (instancetype)initWithCoder:(NSCoder *)coder {
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
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"SortOldestFirst"
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.rightBarButtonItem = self.markBarButtonItem;
    self.markBarButtonItem.enabled = NO;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ArticleCellWithThumbnail" bundle:nil] forCellWithReuseIdentifier:@"ArticleCellWithThumbnail"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"NoThumbnailArticleCell" bundle:nil] forCellWithReuseIdentifier:@"NoThumbnailArticleCell"];
    self.collectionView.scrollsToTop = NO;
    [self.collectionView addGestureRecognizer:self.markGesture];
    [self.collectionView addGestureRecognizer:self.sideGestureRecognizer];
    
    self.itemProviderOperationQueue = [[NSOperationQueue alloc] init];
    self.operations = [NSMutableDictionary dictionary];
    self.fetchedItemProviders = [NSMutableDictionary dictionary];
    
    comingFromDetail = NO;
    markingAllItemsRead = NO;
    self.aboutToFetch = NO;
    
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
    if (!comingFromDetail) {
        [self configureView];
    }
    comingFromDetail = NO;
}

- (void)contextSaved:(NSNotification*)notification {
    if (markingAllItemsRead) {
        markingAllItemsRead = NO;
        self.aboutToFetch= YES;
        BOOL success = [self.fetchedResultsController performFetch:nil];
        self.aboutToFetch = NO;
        if (success) {
            fetchedItems = self.fetchedResultsController.fetchedObjects;
        }
        [self refresh];
    }
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"HideRead"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ShowThumbnails"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ShowFavicons"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"SortOldestFirst"];
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"] == YES) && item.imageLink) {
        ArticleCellWithThumbnail *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ArticleCellWithThumbnail" forIndexPath:indexPath];
        if (self.fetchedItemProviders[indexPath]) {
            cell.item = self.fetchedItemProviders[indexPath];
        } else {
            [self performCellPrefetchForIndexPath:indexPath];
        }
        return cell;
    } else {
        ArticleCellNoThumbnail *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NoThumbnailArticleCell" forIndexPath:indexPath];
        if (self.fetchedItemProviders[indexPath]) {
            cell.item = self.fetchedItemProviders[indexPath];
        } else {
            [self performCellPrefetchForIndexPath:indexPath];
        }
        return cell;
    }
}


#pragma mark - Table view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Item *selectedItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (selectedItem && selectedItem.myId) {
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        [self performSegueWithIdentifier:@"showArticleSegue" sender:selectedItem];
        if (selectedItem.unread) {
            selectedItem.unread = NO;
        }
        [self updateUnreadCount:@[@(selectedItem.myId)] atIndexPaths:@[indexPath]];
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showArticleSegue"]) {
        ArticleController *articleController = (ArticleController *)segue.destinationViewController;
        articleController.feed = self.feed;
        articleController.folderId = self.folderId;
        articleController.aboutToFetch = YES;
        [articleController.fetchedResultsController performFetch:nil];
        articleController.aboutToFetch = NO;
        articleController.selectedArticle = (Item *)sender;
        articleController.items = self.fetchedResultsController.fetchedObjects;
        articleController.articleListcontroller = self;
        comingFromDetail = YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        if (!self.fetchedItemProviders[indexPath]) {
            [self performCellPrefetchForIndexPath:indexPath];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        if (self.operations[indexPath]) {
            [self cancelCellPrefetchForIndexPath:indexPath];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
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
    NSMutableArray *idsToMarkRead = [NSMutableArray new];
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
    long unreadCount = [self unreadCount];
    if (unreadCount > 0) {
        if (self.fetchedResultsController.fetchedObjects.count > 0) {
            NSInteger index = 0;
            for (Item *item in self.fetchedResultsController.fetchedObjects) {
                if (item.unread) {
                    item.unread = NO;
                    [idsToMarkRead addObject:@(item.myId)];
                    [indexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
                }
                index += 1;
            }
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
    [self updateUnreadCount:idsToMarkRead atIndexPaths:indexPaths];
}

- (void)markRowsRead {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MarkWhileScrolling"]) {
        long unreadCount = [self unreadCount];
        if (unreadCount > 0) {
            NSArray *visibleCells = self.collectionView.indexPathsForVisibleItems;
            if (visibleCells.count > 0) {
                NSInteger topVisibleRow = [[visibleCells valueForKeyPath:@"@min.item"] integerValue];
                if (self.fetchedResultsController.fetchedObjects.count > 0) {
                    NSMutableArray *idsToMarkRead = [NSMutableArray new];
                    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
                    NSInteger index = 0;
                    for (Item *item in self.fetchedResultsController.fetchedObjects) {
                        if (index > topVisibleRow) {
                            break;
                        }
                        if (item.unread) {
                            item.unread = NO;
                            [indexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
                            [idsToMarkRead addObject:@(item.myId)];
                        }
                        index += 1;
                    }
                    unreadCount = unreadCount - idsToMarkRead.count;
                    [self updateUnreadCount:idsToMarkRead atIndexPaths:indexPaths];
                    self.markBarButtonItem.enabled = (unreadCount > 0);
                }
            }
        }
    }
}

- (void)updateUnreadCount:(NSArray *)itemsToUpdate atIndexPaths:(NSArray *)indexPaths {
    [[OCNewsHelper sharedHelper] markItemsReadOffline:[NSMutableSet setWithArray:itemsToUpdate]];
    for (NSIndexPath *indexPath in indexPaths) {
        [self performCellPrefetchForIndexPath:indexPath];
    }
    [self refresh];
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
    if([keyPath isEqual:@"HideRead"]) {
        [self refresh];
    }
    if([keyPath isEqual:@"ShowThumbnails"] || [keyPath isEqual:@"ShowFavicons"]) {
        [self refresh];
    }
    if([keyPath isEqual:@"SortOldestFirst"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SortOldestFirst"]) {
            NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:YES];
            [self.fetchedResultsController.fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        } else {
            NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"myId" ascending:NO];
            [self.fetchedResultsController.fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        }
        [self refresh];
    }
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
        
        CGPoint p = [gestureRecognizer locationInView:self.collectionView];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
        if (indexPath == nil) {
            //            NSLog(@"swipe on table view but not on a row");
        } else {
            if (indexPath.section == 0) {
                @try {
                    Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    if (item && item.myId) {
                        if (item.unread) {
                            item.unread = NO;
                            [self updateUnreadCount:@[@(item.myId)] atIndexPaths:@[indexPath]];
                        } else {
                            if (item.starred) {
                                item.starred = NO;
                                [[OCNewsHelper sharedHelper] unstarItemOffline:item.myId];
                            } else {
                                item.starred = YES;
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
    [Messenger showMessageWithTitle:[n.userInfo objectForKey:@"Title"]
                               body:[n.userInfo objectForKey:@"Message"]
                              theme:MessageThemeError];
}

- (NSInteger)unreadCount {
    NSInteger result = 0;
    if (self.feed) {
        if ((self.feed.myId == -2) && (self.folderId > 0)) {
            Folder *folder = [[OCNewsHelper sharedHelper] folderWithId:self.folderId];
            result = folder.unreadCount;
        } else {
            result = self.feed.unreadCount;
        }
    }
    return result;
}

- (IBAction)onSideGestureRecognizer:(id)sender {
    if ([self.sideGestureRecognizer translationInView:self.collectionView].x > 10) {
        [UIView animateWithDuration:0.3 animations:^{
            self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        } completion:^(BOOL finished) {
            if (finished) {
                [self.collectionView reloadData];
            }
        }];
    }
}


#pragma mark - Prefetching Functions

- (void)performCellPrefetchForIndexPath:(NSIndexPath *)indexPath {
    if (![self.collectionView isIndexPathAvailable:indexPath]) {
        return;
    }
    Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (!item) {
        return;
    }
    
    Feed *feed = [OCNewsHelper.sharedHelper feedWithId:item.feedId];
    ItemProviderStruct *itemData = [[ItemProviderStruct alloc] init];
    itemData.title = item.title;
    itemData.myID = item.myId;
    itemData.author = item.author;
    itemData.pubDate = item.pubDate;
    itemData.body = item.body;
    itemData.feedId = item.feedId;
    itemData.starred = item.starred;
    itemData.unread = item.unread;
    itemData.imageLink = item.imageLink;
    itemData.readable = item.readable;
    itemData.url = item.url;
    itemData.favIconLink = feed.faviconLink;
    itemData.feedTitle = feed.title;
    itemData.feedPreferWeb = feed.preferWeb;
    itemData.feedUseReader = feed.useReader;

    ItemProvider *provider = [[ItemProvider alloc] initWithItem:itemData];

    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakBlockOperation = blockOperation;
    __weak typeof(self) weakSelf = self;
    __weak ItemProvider *weakProvider = provider;
    __weak NSIndexPath *weakIndexPath = indexPath;
    
    [blockOperation addExecutionBlock:^{
        if (weakBlockOperation.isCancelled) {
            weakSelf.operations[weakIndexPath] = nil;
            return;
        }
        [weakProvider configure];
//        weakSelf.fetchedItemProviders[indexPath] = weakProvider;
//        weakSelf.operations[indexPath] = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *visibleCellIndexPaths = [weakSelf.collectionView indexPathsForVisibleItems];
            if ([visibleCellIndexPaths containsObject:weakIndexPath]) {
                UICollectionViewCell *cell = [weakSelf.collectionView cellForItemAtIndexPath:weakIndexPath];
                ((BaseArticleCell *)cell).item = weakProvider;
            }
        });
    }];
    [self.itemProviderOperationQueue addOperation:blockOperation];
    self.operations[indexPath] = blockOperation;
    self.fetchedItemProviders[indexPath] = provider;
}

- (void)cancelCellPrefetchForIndexPath:(NSIndexPath *)indexPath {
    if (self.operations[indexPath]) {
        NSBlockOperation *blockOperation = self.operations[indexPath];
        [blockOperation cancel];
        self.operations[indexPath] = nil;
    }
}

@end
