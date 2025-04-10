//
//  JCAutheticationParameters.h
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthToken.h"

@interface JCAuthKeychain : NSObject

@property (nonatomic, readonly) JCAuthToken *authToken;
@property (nonatomic, readonly) BOOL isAuthenticated;

- (BOOL)setAuthToken:(JCAuthToken *)authToken error:(NSError *__autoreleasing *)error;
- (void)logout;

@end