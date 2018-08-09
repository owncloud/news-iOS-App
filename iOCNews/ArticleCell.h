//
//  ArticleCell.h
//  iOCNews
//
//  Created by Peter Hedlund on 7/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

@import WebKit;
@import UIKit;

#import "Item.h"

@interface ArticleCell : UICollectionViewCell

@property (strong, nonatomic) Item *item;
@property (strong, nonatomic) WKWebView *webView;

@end
