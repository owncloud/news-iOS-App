//
//  PHThemeManager.h
//  iOCNews
//
//  Created by Peter Hedlund on 10/29/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PHTheme) {
    PHThemeDefault,
    PHThemeSepia,
    PHThemeNight
};

@interface PHThemeManager : NSObject

+ (PHThemeManager *)sharedManager;

@property(assign) PHTheme currentTheme;

@end
