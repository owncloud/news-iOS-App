//
//  PHPrefViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012-2017 Peter Hedlund. All rights reserved.
//

#import "PHPrefViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "UIColor+PHColor.h"

#define MIN_FONT_SIZE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 11 : 9)
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH 45 //%
#define MAX_WIDTH 95 //%

@interface PHPrefViewController () {
    BOOL starred;
    BOOL unread;
}

@end

@implementation PHPrefViewController

@synthesize delegate = _delegate;


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
    [self.starButton.layer setCornerRadius:8.0f];
    [self.starButton.layer setMasksToBounds:YES];
    [self.starButton.layer setBorderWidth:0.75f];
    [self.starButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.markUnreadButton.layer setCornerRadius:8.0f];
    [self.markUnreadButton.layer setMasksToBounds:YES];
    [self.markUnreadButton.layer setBorderWidth:0.75f];
    [self.markUnreadButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseFontSizeButton.layer setCornerRadius:8.0f];
    [self.decreaseFontSizeButton.layer setMasksToBounds:YES];
    [self.decreaseFontSizeButton.layer setBorderWidth:0.75f];
    [self.decreaseFontSizeButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseFontSizeButton.layer setCornerRadius:8.0f];
    [self.increaseFontSizeButton.layer setMasksToBounds:YES];
    [self.increaseFontSizeButton.layer setBorderWidth:0.75f];
    [self.increaseFontSizeButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
      
    [self.decreaseLineHeightButton.layer setCornerRadius:8.0f];
    [self.decreaseLineHeightButton.layer setMasksToBounds:YES];
    [self.decreaseLineHeightButton.layer setBorderWidth:0.75f];
    [self.decreaseLineHeightButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseLineHeightButton.layer setCornerRadius:8.0f];
    [self.increaseLineHeightButton.layer setMasksToBounds:YES];
    [self.increaseLineHeightButton.layer setBorderWidth:0.75f];
    [self.increaseLineHeightButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.decreaseMarginButton.layer setCornerRadius:8.0f];
    [self.decreaseMarginButton.layer setMasksToBounds:YES];
    [self.decreaseMarginButton.layer setBorderWidth:0.75f];
    [self.decreaseMarginButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
    
    [self.increaseMarginButton.layer setCornerRadius:8.0f];
    [self.increaseMarginButton.layer setMasksToBounds:YES];
    [self.increaseMarginButton.layer setBorderWidth:0.75f];
    [self.increaseMarginButton.layer setBorderColor:[[UIColor darkGrayColor] CGColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBackgrounds];
    starred = NO;
    unread = NO;
    if (_delegate != nil) {
        starred = [_delegate starred];
        [[NSUserDefaults standardUserDefaults] setBool:starred forKey:@"Starred"];
        if (starred) {
            [self.starButton setImage:[UIImage imageNamed:@"starred"] forState:UIControlStateNormal];
        } else {
            [self.starButton setImage:[UIImage imageNamed:@"unstarred"] forState:UIControlStateNormal];
        }
        unread = [_delegate unread];
        [[NSUserDefaults standardUserDefaults] setBool:unread forKey:@"Unread"];
        if (unread) {
            [self.markUnreadButton setImage:[UIImage imageNamed:@"unread"] forState:UIControlStateNormal];
        } else {
            [self.markUnreadButton setImage:[UIImage imageNamed:@"read"] forState:UIControlStateNormal];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)updateBackgrounds {
    self.view.backgroundColor = [UIColor popoverBackgroundColor];
    
    UIColor *buttonColor = [UIColor popoverButtonColor];
    self.starButton.backgroundColor = buttonColor;
    self.markUnreadButton.backgroundColor = buttonColor;
    self.decreaseFontSizeButton.backgroundColor = buttonColor;
    self.increaseFontSizeButton.backgroundColor = buttonColor;
    self.decreaseLineHeightButton.backgroundColor = buttonColor;
    self.increaseLineHeightButton.backgroundColor = buttonColor;
    self.decreaseMarginButton.backgroundColor = buttonColor;
    self.increaseMarginButton.backgroundColor = buttonColor;
 
    CGColorRef borderColor = [[UIColor popoverBorderColor] CGColor];
    self.starButton.layer.borderColor = borderColor;
    self.markUnreadButton.layer.borderColor = borderColor;
    self.decreaseFontSizeButton.layer.borderColor = borderColor;
    self.increaseFontSizeButton.layer.borderColor = borderColor;
    self.decreaseLineHeightButton.layer.borderColor = borderColor;
    self.increaseLineHeightButton.layer.borderColor = borderColor;
    self.decreaseMarginButton.layer.borderColor = borderColor;
    self.increaseMarginButton.layer.borderColor = borderColor;
    
    UIColor *iconColor = [UIColor popoverIconColor];
    self.starButton.tintColor = iconColor;
    self.markUnreadButton.tintColor = iconColor;
    self.decreaseFontSizeButton.tintColor = iconColor;
    self.increaseFontSizeButton.tintColor = iconColor;
    self.decreaseLineHeightButton.tintColor = iconColor;
    self.increaseLineHeightButton.tintColor = iconColor;
    self.decreaseMarginButton.tintColor = iconColor;
    self.increaseMarginButton.tintColor = iconColor;
}

- (IBAction)onButtonTap:(UIButton *)sender {
    NSString *reload = @"true";
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (sender == self.starButton) {
        starred = !starred;
        [prefs setBool:starred forKey:@"Starred"];
        if (starred) {
            [self.starButton setImage:[UIImage imageNamed:@"starred"] forState:UIControlStateNormal];
        } else {
            [self.starButton setImage:[UIImage imageNamed:@"unstarred"] forState:UIControlStateNormal];
        }
        reload = @"false";
    }

    if (sender == self.markUnreadButton) {
        unread = !unread;
        [prefs setBool:unread forKey:@"Unread"];
        if (unread) {
            [self.markUnreadButton setImage:[UIImage imageNamed:@"unread"] forState:UIControlStateNormal];
        } else {
            [self.markUnreadButton setImage:[UIImage imageNamed:@"read"] forState:UIControlStateNormal];
        }
        reload = @"false";
    }

    if (sender == self.decreaseFontSizeButton) {
        NSInteger currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        
        if (currentFontSize > MIN_FONT_SIZE) {
            --currentFontSize;
        }
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    if (sender == self.increaseFontSizeButton) {
        NSInteger currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        if (currentFontSize < MAX_FONT_SIZE) {
            ++currentFontSize;
        }
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    if (sender == self.decreaseLineHeightButton) {
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (currentLineHeight > MIN_LINE_HEIGHT) {
            currentLineHeight = currentLineHeight - 0.2f;
        }
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }

    if (sender == self.increaseLineHeightButton) {
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (currentLineHeight < MAX_LINE_HEIGHT) {
            currentLineHeight = currentLineHeight + 0.2f;
        }    
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }
    
    if (sender == self.decreaseMarginButton) {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            NSInteger currentMargin = [[prefs valueForKey:@"MarginPortrait"] integerValue];
            if (currentMargin < MAX_WIDTH) {
                currentMargin += 5;
            }
            [prefs setInteger:currentMargin forKey:@"MarginPortrait"];
        } else {
            NSInteger currentMarginLandscape = [[prefs valueForKey:@"MarginLandscape"] integerValue];
            if (currentMarginLandscape < MAX_WIDTH) {
                currentMarginLandscape += 5;
            }
            [prefs setInteger:currentMarginLandscape forKey:@"MarginLandscape"];
        }
    }
    
    if (sender == self.increaseMarginButton) {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            NSInteger currentMargin = [[prefs valueForKey:@"MarginPortrait"] integerValue];
            if (currentMargin > MIN_WIDTH) {
                currentMargin -= 5;
            }
            [prefs setInteger:currentMargin forKey:@"MarginPortrait"];
        } else {
            NSInteger currentMarginLandscape = [[prefs valueForKey:@"MarginLandscape"] integerValue];
            if (currentMarginLandscape > MIN_WIDTH) {
                currentMarginLandscape -= 5;
            }
            [prefs setInteger:currentMarginLandscape forKey:@"MarginLandscape"];
        }
    }
    
    [prefs synchronize];

    if (_delegate != nil) {
		[_delegate settingsChanged:reload newValue:0];
	}
}

@end
