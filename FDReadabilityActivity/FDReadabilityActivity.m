//
//  FDReadabilityActivity.m
//  FeedDeck
//
//  Created by Peter Hedlund on 2/24/13.
//
//

#import "FDReadabilityActivity.h"

@implementation FDReadabilityActivity {
    NSURL *_activityURL;
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"Readability-activity-iPad"];
}

- (NSString *)activityTitle {
    return @"Readability";
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return [[activityItems lastObject] isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"readability://"]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    _activityURL = [activityItems lastObject];
}

- (void)performActivity {
    
    NSURL *inputURL = _activityURL;
    NSString *scheme = inputURL.scheme;

    NSString *activityScheme = nil;
    if ([scheme isEqualToString:@"http"]) {
        activityScheme = @"readability";
    } else if ([scheme isEqualToString:@"https"]) {
        activityScheme = @"readability";
    }
    
    if (activityScheme) {
        NSString *activityURLString = [NSString stringWithFormat:@"readability://add/%@", [inputURL absoluteString]];
        NSURL *activityURL = [NSURL URLWithString:activityURLString];
        
        [self activityDidFinish:[[UIApplication sharedApplication] openURL:activityURL]];
    }
}

@end
