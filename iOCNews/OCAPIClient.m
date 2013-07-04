//
//  OCAPIClient.m
//  iOCNews
//
//  Created by Peter Hedlund on 6/29/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "OCAPIClient.h"
#import "KeychainItemWrapper.h"

//See http://twobitlabs.com/2013/01/objective-c-singleton-pattern-unit-testing/
//Being able to reinitialize a singleton is a no no, but should happen so rarely
//we can live with it?

static const NSString *rootPath = @"index.php/apps/news/api/v1-2/";

static OCAPIClient *_sharedClient = nil;
static dispatch_once_t oncePredicate = 0;

@implementation OCAPIClient

+(OCAPIClient *)sharedClient {
    //static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"Server"], rootPath]]];
    });
    return _sharedClient;
}

-(id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    self.parameterEncoding = AFJSONParameterEncoding;
    
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"iOCNews" accessGroup:nil];
    [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    [self setAuthorizationHeaderWithUsername:[keychain objectForKey:(__bridge id)(kSecAttrAccount)] password:[keychain objectForKey:(__bridge id)(kSecValueData)]];

    return self;
}

+(void)setSharedClient:(OCAPIClient *)client {
    oncePredicate = 0; // resets the once_token so dispatch_once will run again
    _sharedClient = client;
}

@end
