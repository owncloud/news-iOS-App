//
//  ArticleController.h
//  iOCNews
//
//  Created by Peter Hedlund on 7/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "Item+CoreDataClass.h"
#import "ArticleListController.h"

@interface ArticleController : BaseCollectionViewController

@property (nonatomic, strong) Item *selectedArticle;
@property (nonatomic, assign) NSUInteger itemIndex;
@property (nonatomic, strong) ArticleListController *articleListcontroller;

@end
