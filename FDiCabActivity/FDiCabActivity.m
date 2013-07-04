//
//  FDiCabActivity.m
//  FeedDeck
//
//  Created by Peter Hedlund on 2/24/13.
//
//

#import "FDiCabActivity.h"

@implementation FDiCabActivity {
    NSURL *_activityURL;
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"icab-activity"];
}

- (NSString *)activityTitle {
    return @"Open in iCab";
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return [[activityItems lastObject] isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"icabmobile://"]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    _activityURL = [activityItems lastObject];
}

- (void)performActivity {
    
    NSURL *inputURL = _activityURL;
    NSString *scheme = inputURL.scheme;

    NSString *activityScheme = nil;
    if ([scheme isEqualToString:@"http"]) {
        activityScheme = @"icabmobile";
    } else if ([scheme isEqualToString:@"https"]) {
        activityScheme = @"icabmobiles";
    }

    if (activityScheme) {
        NSString *absoluteString = [inputURL absoluteString];
        NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
        NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
        NSString *activityURLString = [activityScheme stringByAppendingString:urlNoScheme];
        NSURL *activityURL = [NSURL URLWithString:activityURLString];
        
        [self activityDidFinish:[[UIApplication sharedApplication] openURL:activityURL]];
    }
}

@end
