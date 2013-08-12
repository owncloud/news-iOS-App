//
//  NSDictionary+HandleNull.m
//  iOCNews
//
//  Created by Peter Hedlund on 8/12/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "NSDictionary+HandleNull.h"

@implementation NSDictionary (HandleNull)

- (id)objectForKeyNotNull:(id)key fallback:(id)fallback {
    id object = [self objectForKey:key];
    if (object == [NSNull null]) {
        return fallback;
    } else {
        return object;
    }
}
@end
