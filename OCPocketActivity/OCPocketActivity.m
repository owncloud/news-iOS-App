//
//  OCPocketActivity.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2014 Peter Hedlund peter.hedlund@me.com
 
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

#import "OCPocketActivity.h"
#import "PocketAPI.h"

@implementation OCPocketActivity {
    NSURL *_activityURL;
}

@synthesize infoAlertView;

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"PocketActivity"];
}

- (NSString *)activityTitle {
    return @"Pocket";
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			NSURL *pocketURL = [NSURL URLWithString:[[PocketAPI pocketAppURLScheme] stringByAppendingString:@":test"]];

			if ([[UIApplication sharedApplication] canOpenURL:pocketURL] || [PocketAPI sharedAPI].loggedIn) {
				return YES;
			}
		}
	}

	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    _activityURL = [activityItems lastObject];
}

- (void)performActivity {
    
    if ([PocketAPI sharedAPI].loggedIn) {
        
        [[PocketAPI sharedAPI] saveURL:_activityURL handler: ^(PocketAPI *API, NSURL *URL, NSError *error) {
            if(error) {
                self.infoAlertView.message = @"There was an error adding the article.";
                [self.infoAlertView show];
            } else {
                self.infoAlertView.message = @"The article was added successfully.";
                [self.infoAlertView show];
            }
        }];
        
        [self activityDidFinish:YES];
    } else {
        [[PocketAPI sharedAPI] loginWithHandler:^(PocketAPI *api, NSError *error) {
            if (error) {
                self.infoAlertView.message = @"There was an error logging in.";
                [self.infoAlertView show];
                [self activityDidFinish:YES];
            } else {
                [self performActivity];
            }
        }];
    }
}

- (UIAlertView*)infoAlertView {
    if (!infoAlertView) {
        infoAlertView = [[UIAlertView alloc] initWithTitle:[self activityTitle] message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    }
    return infoAlertView;
}

@end
