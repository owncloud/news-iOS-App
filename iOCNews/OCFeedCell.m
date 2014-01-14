//
//  FeedCell.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2013 Peter Hedlund peter.hedlund@me.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *************************************************************************/

#import "OCFeedCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation OCFeedCell

@synthesize activityIndicator, countBadge;

- (UIActivityIndicatorView *)activityIndicator {
    
    if (!activityIndicator) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return activityIndicator;
}

- (OCBadgeView *)countBadge {
    
    if (!countBadge) {
        countBadge = [[OCBadgeView alloc] initWithFrame:CGRectMake(0, 0, 55, 44)];
        countBadge.value = 888;
    }
    return countBadge;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.contentView addSubview:self.countBadge];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //self.imageView.layer.masksToBounds = YES; impacts scrolling
    self.imageView.layer.cornerRadius = 2.0;
    int imageViewOffset = 15;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowFavicons"]) {
        self.imageView.frame = CGRectMake(5, 10, 22, 22);
        imageViewOffset = 37;
    } else {
        self.imageView.frame = CGRectZero;
    }
    int accessoryOffset = 15;
    if (self.accessoryType == UITableViewCellAccessoryNone) {
        accessoryOffset = -18;
    }
    self.countBadge.frame = CGRectMake(self.contentView.frame.size.width - self.countBadge.frame.size.width + accessoryOffset,
                                       self.countBadge.frame.origin.y,
                                       self.countBadge.frame.size.width,
                                       self.countBadge.frame.size.height);
    self.textLabel.frame = CGRectMake(imageViewOffset,
                                      self.textLabel.frame.origin.y,
                                      self.countBadge.frame.origin.x - imageViewOffset,
                                      self.textLabel.frame.size.height);
}

@end
