//
//  FDDrawerController.h
//  FeedDeck
//
//  Created by Peter Hedlund on 5/31/14.
//
//

#import "MMDrawerController+Subclass.h"
#import "OCWebController.h"

@interface FDTopDrawerController : MMDrawerController

@property (strong, nonatomic) OCWebController *webController;

@end
