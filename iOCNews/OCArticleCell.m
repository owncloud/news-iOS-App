//
//  ArticleCell.m
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

#import "OCArticleCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation OCArticleCell

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

- (void)layoutSubviews {
    [super layoutSubviews];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"] && self.articleImage.image) {
            [self.articleImageWidthConstraint setConstant:56.0f];
            [self.titleLabelLeftConstraint setConstant:76.0f];
            [self.favIconLeftConstraint setConstant:28.0f];
            self.summaryTopConstraint.constant = 4.0f;
        } else {
            [self.articleImageWidthConstraint setConstant:0.0f];
            [self.titleLabelLeftConstraint setConstant:10.0f];
            [self.favIconLeftConstraint setConstant:0.0f];
            self.summaryTopConstraint.constant = -4.0f;
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowFavicons"] && self.favIconImage.image) {
            [self.favIconWidthConstraint setConstant:16.0f];
            [self.favIconLeftConstraint setConstant:28.0f];
        } else {
            [self.favIconWidthConstraint setConstant:0.0f];
            [self.favIconLeftConstraint setConstant:0.0f];
        }
        self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.frame.size.width;

    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowThumbnails"] && self.articleImage.image) {
            [self.articleImageWidthConstraint setConstant:112.0f];
            [self.titleLabelLeftConstraint setConstant:152.0f];
        } else {
            [self.articleImageWidthConstraint setConstant:112.0f];
            [self.titleLabelLeftConstraint setConstant:20.0f];
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowFavicons"] && self.favIconImage.image) {
            [self.favIconWidthConstraint setConstant:16.0f];
            [self.favIconLeftConstraint setConstant:28.0f];
        } else {
            [self.favIconWidthConstraint setConstant:0.0f];
            [self.favIconLeftConstraint setConstant:0.0f];
        }
        self.titleLabel.preferredMaxLayoutWidth = self.containerView.frame.size.width - 20;
    }
    self.summaryLabel.preferredMaxLayoutWidth = self.summaryLabel.frame.size.width;

    [super layoutSubviews];
}

@end
