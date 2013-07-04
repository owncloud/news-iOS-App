//
//  PHPrefViewController.h
//  PMC Reader
//
//  Created by Peter Hedlund on 8/2/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSegmentedControl.h"

@protocol PHPrefViewControllerDelegate
- (void)settingsChanged:(NSString*)setting newValue:(NSUInteger)value;
@end

@interface PHPrefViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *backgroundSegmented;
@property (weak, nonatomic) IBOutlet MCSegmentedControl *fontSizeSegmented;
@property (weak, nonatomic) IBOutlet MCSegmentedControl *lineHeightSegmented;
@property (weak, nonatomic) IBOutlet MCSegmentedControl *marginSegmented;

@property (nonatomic, strong) id<PHPrefViewControllerDelegate> delegate;

- (IBAction)doSegmentedValueChanged:(id)sender;

@end
