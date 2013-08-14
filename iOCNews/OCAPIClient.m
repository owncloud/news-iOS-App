//
//  OCAPIClient.m
//  iOCNews
//

/************************************************************************
 
 Copyright 2013 Peter Hedlund peter.hedlund@me.com
 
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
    BOOL allowInvalid = [[NSUserDefaults standardUserDefaults] boolForKey:@"AllowInvalidSSLCertificate"];
    self.allowsInvalidSSLCertificate = allowInvalid;

    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"iOCNews" accessGroup:nil];
    [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    [self setAuthorizationHeaderWithUsername:[keychain objectForKey:(__bridge id)(kSecAttrAccount)] password:[keychain objectForKey:(__bridge id)(kSecValueData)]];

    return self;
}

+(void)setSharedClient:(OCAPIClient *)client {
    oncePredicate = 0; // resets the once_token so dispatch_once will run again
    _sharedClient = client;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    AFHTTPRequestOperation *operation = [super HTTPRequestOperationWithRequest:urlRequest success:success failure:failure];

    BOOL allowInvalid = [[NSUserDefaults standardUserDefaults] boolForKey:@"AllowInvalidSSLCertificate"];
    if (allowInvalid) {
        [operation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
            }
            
        }];
    }
    return operation;
}

@end
