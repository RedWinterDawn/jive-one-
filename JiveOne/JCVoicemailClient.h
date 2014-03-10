//
//  JCVoicemailClient.h
//  JiveOne
//
//  Created by Daniel George on 3/7/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCVoicemailClient : NSObject
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
+ (JCVoicemailClient*)sharedClient;
-(void)fetchExtensions:(void (^)(id JSON))success
               failure:(void (^)(NSError *err))failure;

@end
