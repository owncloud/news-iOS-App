//
//  OCTextView.m
//  iOCNews
//
//  Created by Peter Hedlund on 1/15/14.
//  Copyright (c) 2014 Peter Hedlund. All rights reserved.
//

#import "OCTextView.h"

@implementation OCTextView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"contentSize"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.bounds.size, [self intrinsicContentSize])) {
        [self invalidateIntrinsicContentSize];
    }
}

- (UIEdgeInsets)textContainerInset {
    return UIEdgeInsetsZero;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    UITextView *textView = (UITextView *)object;
    CGFloat topOffset = (textView.bounds.size.height - textView.contentSize.height * textView.zoomScale) / 2;
    topOffset = topOffset < 0 ? 0 : topOffset;
    textView.contentOffset = CGPointMake(0, -topOffset);
}

@end
