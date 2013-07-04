//
//  OCAPIClient.h
//  iOCNews
//
//  Created by Peter Hedlund on 6/29/13.
//  Copyright (c) 2013 Peter Hedlund. All rights reserved.
//

#import "AFNetworking.h"

@interface OCAPIClient : AFHTTPClient

+(OCAPIClient *)sharedClient;
+(void)setSharedClient:(OCAPIClient *)client;

@end
