//
//  UICollectionView+ValidIndexPath.h
//  iOCNews
//
//  Created by Peter Hedlund on 10/18/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UICollectionView (ValidIndexPath)

- (BOOL)isIndexPathAvailable:(NSIndexPath *)indexPath;
- (void)scrollToItemIfAvailable:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
