//
//  NSDictionary+HandleNull.h
//  iOCNews
//
//  Created by Peter Hedlund on 8/12/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (HandleNull)

- (id)objectForKeyNotNull:(id)key fallback:(id)fallback;

@end
