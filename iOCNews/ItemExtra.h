//
//  ItemExtra.h
//  iOCNews
//
//  Created by Peter Hedlund on 8/11/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item;

@interface ItemExtra : NSManagedObject

@property (nonatomic, retain) NSString * readable;
@property (nonatomic, retain) Item *parent;

@end
