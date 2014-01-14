//
//  FeedCell.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2014 Peter Hedlund peter.hedlund@me.com
 
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

@synthesize countBadge;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.accessoryView = self.countBadge;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.layer.cornerRadius = 2.0f;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowFavicons"]) {
        self.imageViewWidthConstraint.constant = 22;
        self.imageViewLeadingConstraint.constant = 5;
        self.textLabelLeadingConstraint.constant = 35;
    } else {
        self.imageViewWidthConstraint.constant = 0;
        self.imageViewLeadingConstraint.constant = 5;
        self.textLabelLeadingConstraint.constant = 15;
    }
    [super layoutSubviews];
}

- (MLPAccessoryBadge *)countBadge {
    if (!countBadge) {
        countBadge = [MLPAccessoryBadgeChevron new];
        [countBadge.textLabel setFont:[UIFont boldSystemFontOfSize:16]];
        [countBadge setChevronStrokeWidth:2.0f];
        [countBadge setCornerRadius:100];
        [countBadge setBackgroundColor:[UIColor colorWithRed:0.58f green:0.61f blue:0.65f alpha:1.0f]];
        [countBadge.textLabel setShadowOffset:CGSizeZero];
        [countBadge setHighlightAlpha:0];
        [countBadge setShadowAlpha:0];
        [countBadge setGradientAlpha:0];
    }
    return countBadge;
}

@end
