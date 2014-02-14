//
//  JCOsgiClient.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface JCOsgiClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

+ (instancetype)sharedClient;

- (void) RetrieveClientEntitites:(void (^)(id JSON))success
                            failure:(void (^)(NSError *err))failure;

- (void) RetrieveMyEntitity:(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure;

- (void) RetrieveMyCompanyWithCompany:(NSString*)company :(void (^)(id JSON))success
                    failure:(void (^)(NSError *err))failure;

- (void) RetrieveConversations:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

- (void) RequestSocketSession:(void (^)(id JSON))success
                       failure:(void (^)(NSError *err))failure;

- (void) OAuthLoginWithUsername:(NSString*)username password:(NSString*)password success:(void (^)(id JSON))success
                      failure:(void (^)(NSError *err))failure;

- (void) SubscribeToSocketEventsWithAuthToken:(NSString*)token subscriptions:(NSDictionary*)subscriptions success:(void (^)(id JSON))success
                                      failure:(void (^)(NSError* err))failure;


@end
