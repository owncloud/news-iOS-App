//
//  OCArticleImage.h
//  iOCNews
//
//  Created by Peter Hedlund on 6/30/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCArticleImage : NSObject

+ (NSString *) findImage:(NSString *)htmlString;
+ (NSArray*)imagesToSkip;

@end
