//
//  JCAutheticationParameters.h
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthInfo.h"

@interface JCAuthKeychain : NSObject

@property (nonatomic, readonly) JCAuthInfo *authInfo;
@property (nonatomic, readonly) BOOL isAuthenticated;

- (BOOL)setAuthInfo:(JCAuthInfo *)authInfo error:(NSError *__autoreleasing *)error;
- (void)logout;

@end