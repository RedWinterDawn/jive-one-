//
//  JCV5ApiClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApiClient.h"

@interface JCV5ApiClient : JCApiClient

+ (instancetype)sharedClient;

- (BOOL)isOperationRunning:(NSString *)operationName;

@end
