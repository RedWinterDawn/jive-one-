//
//  JCAuthClient.h
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "User.h"
#import "Line.h"
#import "PBX.h"

extern NSString *const kJCAuthManagerUserLoggedOutNotification;
extern NSString *const kJCAuthManagerUserAuthenticatedNotification;
extern NSString *const kJCAuthManagerUserLoadedMinimumDataNotification;
extern NSString *const kJCAuthManagerLineChangedNotification;

typedef void (^CompletionBlock) (BOOL success, NSError *error);

@interface JCAuthClient : NSObject


- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionBlock)completed;


@property (nonatomic, strong) Line *line;
@property (nonatomic, readonly) User *user;
@property (nonatomic, readonly) PBX *pbx;

@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) NSString *jiveUserId;
@property (nonatomic, readonly) BOOL userLoadedMinimumData;


@property (nonatomic, strong) NSString *deviceToken;

@property NSInteger *maxloginAttempts;
@end
