//
//  JCAppDelegate.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCAppDelegate : UIResponder <UIApplicationDelegate>
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
- (void)incrementBadgeCountForConversation:(NSString *)conversationId;
- (void)incrementBadgeCountForVoicemail;
- (void)decrementBadgeCountForConversation:(NSString *)conversationId;
- (void)decrementBadgeCountForVoicemail;
- (void)clearBadgeCountForVoicemail;
- (void)clearBadgeCountForConversation:(NSString *)conversationId;

@end
