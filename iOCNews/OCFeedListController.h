//
//  FeedListController.h
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

#import <UIKit/UIKit.h>
#import "OCArticleListController.h"
#import "OCFeedSettingsController.h"
#import "MSCMoreOptionTableViewCellDelegate.h"

@interface OCFeedListController : UITableViewController <NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate, OCFeedSettingsDelegate, MSCMoreOptionTableViewCellDelegate>

@property (strong, nonatomic) OCArticleListController *detailViewController;
@property (nonatomic, retain) NSFetchedResultsController *specialFetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *foldersFetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *feedsFetchedResultsController;

@property (nonatomic, strong, readonly) UIBarButtonItem *addBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong, readonly) UIRefreshControl *feedRefreshControl;

@property (nonatomic, strong, readonly) UIPopoverController *settingsPopover;
@property (strong, nonatomic) UIActionSheet *gearActionSheet;
@property (nonatomic, strong, readonly) UIAlertView *addFolderAlertView;
@property (nonatomic, strong, readonly) UIAlertView *renameFolderAlertView;
@property (nonatomic, strong, readonly) UIAlertView *addFeedAlertView;

@property (nonatomic, assign) NSInteger folderId;

- (IBAction) doRefresh:(id)sender;
- (IBAction) doSettings:(id)sender;

- (void)drawerOpened:(NSNotification *)n;
- (void)drawerClosed:(NSNotification *)n;

@end
