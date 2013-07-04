//
//  FDInstapaperActivity.m
//  FeedDeck
//
//  Created by Peter Hedlund on 2/24/13.
//
//

#import "FDInstapaperActivity.h"

@implementation FDInstapaperActivity {
    NSURL *_activityURL;
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"instapaper"];
}

- (NSString *)activityTitle {
    return @"Instapaper";
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return [[activityItems lastObject] isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ihttp://"]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    _activityURL = [activityItems lastObject];
}

- (void)performActivity {

    NSString *absoluteString = [_activityURL absoluteString];
    NSString *activityURLString = @"i";
    activityURLString = [activityURLString stringByAppendingString:absoluteString];
    NSURL *activityURL = [NSURL URLWithString:activityURLString];
    
    [self activityDidFinish:[[UIApplication sharedApplication] openURL:activityURL]];

}

@end
