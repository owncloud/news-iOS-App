//
//  UIColor+PHColor.h
//
//  Created by Peter Hedlund on 9/29/13.
//  Copyright (c) 2013-2019 Peter Hedlund. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (PHColor)

@property(class, nonatomic, readonly, nonnull) UIColor *ph_backgroundColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_cellBackgroundColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_cellSelectionColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_iconColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_textColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_readTextColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_linkColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_popoverBackgroundColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_popoverButtonColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_popoverBorderColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_popoverIconColor;
@property(class, nonatomic, readonly, nonnull) UIColor *ph_switchTintColor;

@end
