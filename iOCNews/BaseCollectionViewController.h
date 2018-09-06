//
//  BaseCollectionViewController.h
//  iOCNews
//
//  Created by Peter Hedlund on 7/30/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed+CoreDataClass.h"

@interface BaseCollectionViewController : UICollectionViewController

@property (nonatomic, strong) Feed *feed;
@property (nonatomic, assign) NSInteger folderId;
@property (nonatomic, strong, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;

@end
