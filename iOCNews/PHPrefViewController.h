//
//  PHPrefViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012-2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PHPrefViewControllerDelegate
- (BOOL)starred;
- (BOOL)unread;
- (void)settingsChanged:(NSString*)setting newValue:(NSUInteger)value;
@end

@interface PHPrefViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *starButton;
@property (strong, nonatomic) IBOutlet UIButton *markUnreadButton;
@property (strong, nonatomic) IBOutlet UIButton *decreaseFontSizeButton;
@property (strong, nonatomic) IBOutlet UIButton *increaseFontSizeButton;
@property (strong, nonatomic) IBOutlet UIButton *decreaseLineHeightButton;
@property (strong, nonatomic) IBOutlet UIButton *increaseLineHeightButton;
@property (strong, nonatomic) IBOutlet UIButton *decreaseMarginButton;
@property (strong, nonatomic) IBOutlet UIButton *increaseMarginButton;

@property (nonatomic, strong) id<PHPrefViewControllerDelegate> delegate;

- (IBAction)onButtonTap:(UIButton *)sender;

@end
