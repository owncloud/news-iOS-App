//
//  UIColor+PHColor.h
//  PMC Reader
//
//  Created by Peter Hedlund on 9/29/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

//White
#define kPHWhiteBackgroundColor        [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1]
#define kPHWhiteCellBackgroundColor    [UIColor colorWithRed:1.0  green:1.0  blue:1.0  alpha:1]
#define kPHWhiteCellSelectionColor     [UIColor colorWithRed:0.95  green:0.95  blue:0.95  alpha:1]
#define kPHWhiteIconColor              [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:1]
#define kPHWhiteTextColor              [UIColor colorWithRed:0.0  green:0.0  blue:0.0  alpha:1]
#define kPHWhiteLinkColor              [UIColor colorWithRed:0.21 green:0.27 blue:0.35 alpha:1]
#define kPHWhitePopoverBackgroundColor [UIColor colorWithRed:0.941 green:0.949 blue:0.941 alpha:1.00]
#define kPHWhitePopoverButtonColor     [UIColor colorWithRed:0.953 green:0.965 blue:0.961 alpha:1.00]
#define kPHWhitePopoverBorderColor     [UIColor colorWithRed:0.74 green:0.71 blue:0.65 alpha:1]

//Sepia
#define kPHSepiaBackgroundColor        [UIColor colorWithRed:0.96 green:0.94 blue:0.86 alpha:1]
#define kPHSepiaCellBackgroundColor    [UIColor colorWithRed:1.0  green:0.98 blue:0.90 alpha:1]
#define kPHSepiaCellSelectionColor     [UIColor colorWithRed:0.95  green:0.93  blue:0.81  alpha:1]
#define kPHSepiaIconColor              [UIColor colorWithRed:0.36 green:0.24 blue:0.14 alpha:1]
#define kPHSepiaTextColor              [UIColor colorWithRed:0.24 green:0.16 blue:0.10 alpha:1]
#define kPHSepiaLinkColor              [UIColor colorWithRed:0.21 green:0.27 blue:0.35 alpha:1]
#define kPHSepiaPopoverBackgroundColor [UIColor colorWithRed:0.95 green:0.93 blue:0.90 alpha:1]
#define kPHSepiaPopoverButtonColor     [UIColor colorWithRed:0.97 green:0.96 blue:0.94 alpha:1]
#define kPHSepiaPopoverBorderColor     [UIColor colorWithRed:0.74 green:0.71 blue:0.65 alpha:1]


//Night
#define kPHNightBackgroundColor        [UIColor colorWithRed:0.0  green:0.0  blue:0.0  alpha:1]
#define kPHNightCellBackgroundColor    [UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1]
#define kPHNightCellSelectionColor     [UIColor colorWithRed:0.03  green:0.03  blue:0.03  alpha:1]
#define kPHNightIconColor              [UIColor colorWithRed:0.30 green:0.30 blue:0.30 alpha:1]
#define kPHNightTextColor              [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1]
#define kPHNightLinkColor              [UIColor colorWithRed:0.21 green:0.27 blue:0.35 alpha:1]
#define kPHNightPopoverBackgroundColor [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1]
#define kPHNightPopoverButtonColor     [UIColor colorWithRed:0.28 green:0.28 blue:0.28 alpha:1]
#define kPHNightPopoverBorderColor     [UIColor colorWithRed:0.0  green:0.0  blue:0.0  alpha:1]

@interface UIColor (PHColor)

+ (UIColor *)backgroundColor;
+ (UIColor *)cellBackgroundColor;
+ (UIColor *)cellSelectionColor;
+ (UIColor *)iconColor;
+ (UIColor *)textColor;
+ (UIColor *)readTextColor;
+ (UIColor *)linkColor;
+ (UIColor *)popoverBackgroundColor;
+ (UIColor *)popoverButtonColor;
+ (UIColor *)popoverBorderColor;
+ (UIColor *)popoverIconColor;

@end
