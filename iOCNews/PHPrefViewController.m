//
//  PHPrefViewController.m
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

#import "PHPrefViewController.h"

#define MIN_FONT_SIZE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 11 : 9)
#define MAX_FONT_SIZE 30

#define MIN_LINE_HEIGHT 1.2f
#define MAX_LINE_HEIGHT 2.6f

#define MIN_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 380 : 150)
#define MAX_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 700 : 300)

@interface PHPrefViewController ()

@end

@implementation PHPrefViewController
@synthesize backgroundSegmented;
@synthesize fontSizeSegmented;
@synthesize lineHeightSegmented;
@synthesize marginSegmented;
@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.backgroundSegmented setImage:[[UIImage imageNamed:@"background1"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal ]  forSegmentAtIndex:0];
    [self.backgroundSegmented setImage:[[UIImage imageNamed:@"background2"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal ]  forSegmentAtIndex:1];
}

- (void)viewDidUnload
{
    [self setBackgroundSegmented:nil];
    [self setFontSizeSegmented:nil];
    [self setLineHeightSegmented:nil];
    [self setMarginSegmented:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)doSegmentedValueChanged:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl*)sender;
    int newValue = [seg selectedSegmentIndex];
    if (newValue == UISegmentedControlNoSegment) {
        return;
    }

    NSString *setting = nil;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	//int newSize = 0;
    if (seg == backgroundSegmented) {
        //NSLog(@"BG: %d", newValue);
        setting = @"Background";
        [prefs setInteger:newValue forKey:setting];
    }
    
    if (seg == fontSizeSegmented) {
        //NSLog(@"FS: %d", newValue);
        int currentFontSize = [[prefs valueForKey:@"FontSize"] integerValue];
        if (newValue == 0) {
            if (currentFontSize > MIN_FONT_SIZE) {
                --currentFontSize;
            }
        } else {
            if (currentFontSize < MAX_FONT_SIZE) {
                ++currentFontSize;
            }
        }
        NSLog(@"FS: %d", currentFontSize);
        [prefs setInteger:currentFontSize forKey:@"FontSize"];
    }
    
    if (seg == lineHeightSegmented) {
        //NSLog(@"LH: %d", newValue);
        double currentLineHeight = [[prefs valueForKey:@"LineHeight"] doubleValue];
        if (newValue == 0) {
            if (currentLineHeight > MIN_LINE_HEIGHT) {
                currentLineHeight = currentLineHeight - 0.2f;
            }
        } else {
            if (currentLineHeight < MAX_LINE_HEIGHT) {
                currentLineHeight = currentLineHeight + 0.2f;
            }
        }
        NSLog(@"FS: %f", currentLineHeight);
        [prefs setDouble:currentLineHeight forKey:@"LineHeight"];
    }
    
    if (seg == marginSegmented) {
        //NSLog(@"M: %d", newValue);
        int currentMargin = [[prefs valueForKey:@"Margin"] integerValue];
        if (newValue == 0) {
            if (currentMargin < MAX_WIDTH) {
                currentMargin = currentMargin + 20;
            }
        } else {
            if (currentMargin > MIN_WIDTH) {
                currentMargin = currentMargin - 20;
            }
        }
        NSLog(@"FS: %d", currentMargin);
        [prefs setInteger:currentMargin forKey:@"Margin"];
    }

    seg.selectedSegmentIndex = UISegmentedControlNoSegment;
    if (_delegate != nil) {
		[_delegate settingsChanged:setting newValue:newValue];
	}
}
@end
