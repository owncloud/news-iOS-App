//
//  UICollectionView+ValidIndexPath.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/18/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

#import "UICollectionView+ValidIndexPath.h"

@implementation UICollectionView (ValidIndexPath)

- (BOOL)isIndexPathAvailable:(NSIndexPath *)indexPath {
    BOOL result = NO;
    if (self.dataSource) {
        if (indexPath.section < self.numberOfSections) {
            if (indexPath.item < [self numberOfItemsInSection:indexPath.section]) {
                result = YES;
            }
        }
    }
    return result;
}

- (void)scrollToItemIfAvailable:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
    if ([self isIndexPathAvailable:indexPath]) {
        [self scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    }
}

@end
