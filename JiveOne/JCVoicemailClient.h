//
//  JCVoicemailClient.h
//  JiveOne
//
//  Created by Daniel George on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCVoicemailClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

+ (instancetype)sharedClient;

@end
