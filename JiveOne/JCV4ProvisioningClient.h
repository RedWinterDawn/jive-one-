//
//  JCV4ProvisioningClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCV4ProvisioningClient : NSObject
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
+ (instancetype)sharedClient;

- (void) requestProvisioningFile:(NSDictionary *)payload completed:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
@end
