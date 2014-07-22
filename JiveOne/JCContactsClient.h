//
//  JCContactsClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCContactsClient : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

+ (instancetype)sharedClient;

- (void)RetrieveMyInformation:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;
- (void)RetrieveContacts:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;

- (void)SubscribeToSocketEvents:(NSString *)subscriptionURL dataDictionary:(NSDictionary *)dataDictionary;
- (void) RequestSocketSession:(void (^)(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error))completed;

- (void)clearCookies;
@end

