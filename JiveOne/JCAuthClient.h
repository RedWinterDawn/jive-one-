//
//  JCAuthClient.h
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JCAuthClientLoginCompletionBlock) (BOOL success, NSDictionary *authToken, NSError *error);

@interface JCAuthClient : NSObject

@property NSUInteger maxloginAttempts;

- (void)loginWithUsername:(NSString *)username password:(NSString*)password completion:(JCAuthClientLoginCompletionBlock)completion;

@end
