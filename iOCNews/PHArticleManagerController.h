//
//  PHArticleManagerController.h
//  iOCNews
//
//  Created by Peter Hedlund on 10/7/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"

@interface PHArticleManagerController : UIViewController

@property (nonatomic, strong) NSArray<Item *> *articles;
@property (nonatomic, assign) NSUInteger articleIndex;

@end
