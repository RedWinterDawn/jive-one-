//
//  JCAppDelegate.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"

@interface JCAppDelegate : UIResponder <UIApplicationDelegate, UAPushNotificationDelegate, UARegistrationDelegate>
{
    NSInteger previousBadgeCount;
    NSInteger afterBadgeCount;
}

@property (strong, nonatomic) UIWindow *window;
@property BOOL deviceIsIPhone;
@property (nonatomic) BOOL seenTutorial;
- (void)changeRootViewController:(JCRootViewControllerType)type;
- (void)startSocket:(BOOL)inBackground;
- (void)stopSocket;

#pragma mark - Badge Updates
- (void)incrementBadgeCountForConversation:(NSString *)conversationId entryId:(NSString *)entryId;
- (void)incrementBadgeCountForVoicemail:(NSString *)voicemailId;
- (void)decrementBadgeCountForConversation:(NSString *)conversationId;
- (void)decrementBadgeCountForVoicemail:(NSString *)voicemailId;
- (void)clearBadgeCountForVoicemail;
- (void)clearBadgeCountForConversation:(NSString *)conversationId;
- (void)refreshTabBadges:(BOOL)fromRemoteNotification;

@end
