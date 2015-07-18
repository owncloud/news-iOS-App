//
//  OCRoundedImageResponseSerializer.h
//  iOCNews
//
//  Created by Peter Hedlund on 7/14/15.
//  Copyright (c) 2015 Peter Hedlund. All rights reserved.
//

#import "AFURLResponseSerialization.h"

@interface OCRoundedImageResponseSerializer : AFImageResponseSerializer


/**
 The target size applied by the serializer.
 */
@property (readonly, nonatomic) CGSize size;

/**
 Creates and returns a serializer with the specified target size.
 */
+ (instancetype)serializerWithSize:(CGSize)size;


@end
