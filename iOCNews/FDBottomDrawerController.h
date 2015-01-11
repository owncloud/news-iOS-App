//
//  FDDrawerController.h
//  FeedDeck
//
//  Created by Peter Hedlund on 5/31/14.
//
//

#import "MMDrawerController+Subclass.h"
#import "OCFeedListController.h"
#import "OCArticleListController.h"

@interface FDBottomDrawerController : MMDrawerController

@property (strong, nonatomic) OCFeedListController *feedListController;
@property (strong, nonatomic) OCArticleListController *articleListController;

@end
