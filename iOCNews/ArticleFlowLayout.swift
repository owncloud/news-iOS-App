//
//  ArticleFlowLayout.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/27/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import UIKit

@objcMembers
class ArticleFlowLayout: UICollectionViewFlowLayout {

    var currentIndexPath: IndexPath?    
    
    private var computedContentSize: CGSize = .zero
    private var cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let _ = super.shouldInvalidateLayout(forBoundsChange: newBounds)
        return true
    }
    
    override func prepare() {
        guard let cv = self.collectionView else {
            return
        }
        
        computedContentSize = .zero
        cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
        
        let itemWidth = cv.frame.size.width
        let itemHeight = cv.frame.size.height
        
        for section in 0 ..< cv.numberOfSections {
            for item in 0 ..< cv.numberOfItems(inSection: section) {
                let itemFrame = CGRect(x: CGFloat(item) * itemWidth, y: 0, width: itemWidth, height: itemHeight)
                let indexPath = IndexPath(item: item, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = itemFrame
                cellAttributes[indexPath] = attributes
            }
        }
        
        computedContentSize = CGSize(width: itemWidth  * CGFloat(cv.numberOfItems(inSection: 0)), height: itemHeight)
    }
    
    override var collectionViewContentSize: CGSize {
        return computedContentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributeList = [UICollectionViewLayoutAttributes]()
        
        for (_, attributes) in cellAttributes {
            if attributes.frame.intersects(rect) {
                attributeList.append(attributes)
            }
        }
        
        return attributeList
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cellAttributes[indexPath]
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let cv = self.collectionView else {
            return .zero
        }

        if let indexPath = self.currentIndexPath, let layoutAttrs = self.layoutAttributesForItem(at: indexPath) {
            return CGPoint(x: layoutAttrs.frame.origin.x - cv.contentInset.left, y: layoutAttrs.frame.origin.y - cv.contentInset.top)
        } else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }
    }
    
}
