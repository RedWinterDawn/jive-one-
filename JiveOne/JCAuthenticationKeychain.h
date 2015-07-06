//
//  JCAutheticationParameters.h
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCKeychain.h"

@interface JCAuthenticationKeychain : NSObject

@property (nonatomic, readonly) NSString *jiveUserId;
@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSDate *expiration;
@property (nonatomic, readonly) BOOL isAuthenticated;

- (BOOL)setAccessToken:(NSString *)tokenData username:(NSString *)username expiration:(NSDate *)expriation;
- (void)logout;

@end
