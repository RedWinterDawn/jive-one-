//
//  JCAutheticationParameters.h
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCAuthenticationStore : NSObject

@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSString *jiveUserId;

@property (nonatomic, readonly) BOOL isAuthenticated;

- (void)setAuthToken:(NSDictionary *)tokenData;
- (void)logout;

@end
