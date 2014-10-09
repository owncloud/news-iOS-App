//
//  OCSharingProvider.h
//  iOCNews
//
//  Created by Peter Hedlund on 10/8/14.
//  Copyright (c) 2014 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCSharingProvider : UIActivityItemProvider

- (instancetype)initWithPlaceholderItem:(id)placeholderItem subject:(NSString*)subject;

@end
