//
//  BaseCollectionViewController.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/30/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "OCNewsHelper.h"

@interface BaseCollectionViewController () <NSFetchedResultsControllerDelegate> {
    BOOL hideRead;
}

@end

@implementation BaseCollectionViewController

@synthesize feed = _feed;
@synthesize fetchRequest = _fetchRequest;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize folderId;

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
// TODO       if (!aboutToFetch) {
//            return _fetchedResultsController;
//        }
        
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

- (void)setFeed:(Feed *)feed {
    _feed = feed;
    _fetchRequest = nil;
    _fetchedResultsController = nil;
//TODO    [self configureView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    hideRead = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideRead"];
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fetchedResultsController.fetchedObjects.count;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/


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
//            [self configureCell:(OCArticleCell*)[collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
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



@end
