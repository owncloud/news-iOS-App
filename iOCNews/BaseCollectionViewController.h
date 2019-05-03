//
//  BaseCollectionViewController.h
//  iOCNews
//
//  Created by Peter Hedlund on 7/30/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed+CoreDataClass.h"

@interface BaseCollectionViewController : UIViewController

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) Feed *feed;
@property (nonatomic, assign) NSInteger folderId;
@property (nonatomic, assign) BOOL aboutToFetch;
@property (nonatomic, assign) BOOL reloadItemsOnUpdate;
@property (nonatomic, strong, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;

@end
