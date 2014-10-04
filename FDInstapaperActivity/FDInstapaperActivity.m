//
//  FDInstapaperActivity.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2013-2014 Peter Hedlund peter.hedlund@me.com
 
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

#import "FDInstapaperActivity.h"
#import "AFNetworking.h"
#import "PDKeychainBindings.h"

@implementation FDInstapaperActivity {
    NSURL *_activityURL;
}

//@synthesize keychain;
@synthesize loginAlertView;
@synthesize infoAlertView;

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"instapaper"];
}

- (NSString *)activityTitle {
    return @"Instapaper";
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return [[activityItems lastObject] isKindOfClass:[NSURL class]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    _activityURL = [activityItems lastObject];
}

- (void)performActivity {
    //[self.keychain setObject:@"" forKey:(__bridge id)(kSecAttrAccount)];
    //[self.keychain setObject:@"" forKey:(__bridge id)(kSecValueData)];
    
    NSString *username = [[PDKeychainBindings sharedKeychainBindings] objectForKey:(__bridge id)(kSecAttrAccount)];
    if ((username != nil) && (username.length > 0)) {
        NSString *password = [[PDKeychainBindings sharedKeychainBindings] objectForKey:(__bridge id)(kSecValueData)];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
        
        // http://www.instapaper.com/api
        
        NSDictionary *parameters = @{@"username": username, @"password":password, @"url": [_activityURL absoluteString]};
        [manager POST:@"https://www.instapaper.com/api/add" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success: %@", responseObject);
            switch (operation.response.statusCode) {
                case 201:
                    self.infoAlertView.message = @"The article was added successfully.";
                    [self.infoAlertView show];
                    break;
                case 403:
                    [[PDKeychainBindings sharedKeychainBindings] setObject:@"" forKey:(__bridge id)(kSecAttrAccount)];
                    [[PDKeychainBindings sharedKeychainBindings] setObject:@"" forKey:(__bridge id)(kSecValueData)];
                    self.infoAlertView.message = @"Invalid user name or password. Please try again.";
                    [self.infoAlertView show];
                    break;
                default:
                    self.infoAlertView.message = @"There was an error adding the article.";
                    [self.infoAlertView show];
                    break;
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (operation.response.statusCode == 403) {
                [[PDKeychainBindings sharedKeychainBindings] setObject:@"" forKey:(__bridge id)(kSecAttrAccount)];
                [[PDKeychainBindings sharedKeychainBindings] setObject:@"" forKey:(__bridge id)(kSecValueData)];
            }
            self.infoAlertView.message = @"Failed to connect to the Instapaper service.";
            [self.infoAlertView show];
        }];
        [self activityDidFinish:YES];
    } else {
        [self.loginAlertView show];
    }
}

//- (KeychainItemWrapper *)keychain {
//    if (!keychain) {
//        keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"iOCNews-Instapaper" accessGroup:nil];
//        [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
//    }
//    return keychain;
//}

- (UIAlertView*)loginAlertView {
    if (!loginAlertView) {
        loginAlertView = [[UIAlertView alloc] initWithTitle:[self activityTitle] message:@"Enter user name and password." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
        loginAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    }
    return loginAlertView;
}

- (UIAlertView*)infoAlertView {
    if (!infoAlertView) {
        infoAlertView = [[UIAlertView alloc] initWithTitle:[self activityTitle] message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    }
    return infoAlertView;
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"The %@ button was tapped.", [alert buttonTitleAtIndex:buttonIndex]);
    if ([alert isEqual:self.loginAlertView]) {
        if ([[alert buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
            [self activityDidFinish:YES];
        }
        if ([[alert buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
            [[PDKeychainBindings sharedKeychainBindings] setObject:[alert textFieldAtIndex:0].text forKey:(__bridge id)(kSecAttrAccount)];
            [[PDKeychainBindings sharedKeychainBindings] setObject:[alert textFieldAtIndex:1].text forKey:(__bridge id)(kSecValueData)];
            [self performActivity];
        }
    }
}

@end
