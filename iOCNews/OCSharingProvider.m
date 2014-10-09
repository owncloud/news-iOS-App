//
//  OCSharingProvider.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/8/14.
//  Copyright (c) 2014 Peter Hedlund. All rights reserved.
//

#import "OCSharingProvider.h"

@interface OCSharingProvider () {
    NSString *_subject;
}

@end

@implementation OCSharingProvider

- (instancetype)initWithPlaceholderItem:(id)placeholderItem subject:(NSString *)subject {
    self = [super initWithPlaceholderItem:placeholderItem];
    if (self) {
        _subject = subject;
    }
    return self;
}

- (id)item {
    return self.placeholderItem;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType {
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        return _subject;
    }
    return nil;
}

@end
