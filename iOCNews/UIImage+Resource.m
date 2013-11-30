//
//  UIImage+Resource.m
//  iOCNews
//
//  Created by Peter Hedlund on 9/13/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "UIImage+Resource.h"

@implementation UIImage (Resource)

+ (UIImage *)imageResourceNamed:(NSString *)name {
    NSString *resName;
    resName = [NSString stringWithFormat:@"%@-7", name];
    return [self imageNamed:resName];
}

@end
