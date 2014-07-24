//
//  JCJifClient.h
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCJifClient : NSObject
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
+ (instancetype)sharedClient;

//rest calls
- (void)getMailboxReferencesForUser:(NSString*)jiveId completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)getPbxInformationFromUrl:(NSString *)url completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
@end
