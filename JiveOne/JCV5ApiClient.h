//
//  JCV5ApiClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApiClient.h"

typedef void(^JCV5ApiClientCompletionHandler)(BOOL success, id response, NSError *error);

@interface JCV5ApiClient : JCApiClient

+ (instancetype)sharedClient;

- (BOOL)isOperationRunning:(NSString *)operationName;

+ (void)requestPBXInforForUser:(User *)user competion:(JCV5ApiClientCompletionHandler)completion;

@end
