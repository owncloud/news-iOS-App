//
//  OCFolderTableViewController.h
//  iOCNews
//
//  Created by Peter Hedlund on 10/17/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

@protocol OCFolderControllerDelegate
- (void)folderSelected:(NSNumber*)folder;
@end


@interface OCFolderTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
    id<OCFolderControllerDelegate> __unsafe_unretained _delegate;
}

@property (nonatomic, unsafe_unretained) id<OCFolderControllerDelegate> delegate;
@property (strong, nonatomic) Feed *feed;
@property (strong, nonatomic) NSArray *folders;

@end
