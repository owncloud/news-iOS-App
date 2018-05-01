//
//  ArticleCell.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2012-2016 Peter Hedlund peter.hedlund@me.com
 
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
#import "UIColor+PHColor.h"

@implementation OCArticleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectedBackgroundView = [UIView new];
        [self.selectedBackgroundView setBackgroundColor:[UIColor cellBackgroundColor]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    self.mainView.backgroundColor = [UIColor cellBackgroundColor];
    self.mainSubView.backgroundColor = [UIColor cellBackgroundColor];
    self.contentContainerView.backgroundColor = [UIColor cellBackgroundColor];
    self.thumbnailContainerView.backgroundColor = [UIColor cellBackgroundColor];
    self.starContainerView.backgroundColor = [UIColor cellBackgroundColor];
    self.articleImage.backgroundColor = [UIColor cellBackgroundColor];
    self.starImage.backgroundColor = [UIColor cellBackgroundColor];
    self.favIconImage.backgroundColor = [UIColor cellBackgroundColor];
    self.titleLabel.backgroundColor = [UIColor cellBackgroundColor];
    self.dateLabel.backgroundColor = [UIColor cellBackgroundColor];
    self.summaryLabel.backgroundColor = [UIColor cellBackgroundColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [self.contentView setBackgroundColor: [UIColor cellSelectionColor]];
    } else {
        [self.contentView setBackgroundColor: [UIColor clearColor]];
    }
}


@end
