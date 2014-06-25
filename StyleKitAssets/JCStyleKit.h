//
//  JCStyleKit.h
//  JC
//
//  Created by Doug Leonard on 6/25/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface JCStyleKit : NSObject

// iOS Controls Customization Outlets
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* leaveFeedback_ButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* upRightTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* upLeftTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* downRightTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* downLeftTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* moreLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* defaultAvatarLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* voicemailLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* speakerButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* voicemailIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* logoutIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* logOutButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* contactsIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* trashButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* back_buttonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas6Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* messageIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* moreIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas9Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* searchIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* starIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas12Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* typingIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* undoIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* defaultAvatarIconTargets;

// Colors
+ (UIColor*)unSelectedButtonColor;
+ (UIColor*)selectedButtonColor;
+ (UIColor*)deleteColor;
+ (UIColor*)loginColor;

// Drawing Methods
+ (void)drawLeaveFeedback_ButtonWithFrame: (CGRect)frame;
+ (void)drawUpRight;
+ (void)drawUpLeft;
+ (void)drawDownRight;
+ (void)drawDownLeft;
+ (void)drawMoreLogin;
+ (void)drawDefaultAvatarLogin;
+ (void)drawVoicemailLogin;
+ (void)drawSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (void)drawComposeIconWithFrame: (CGRect)frame;
+ (void)drawVoicemailIcon;
+ (void)drawLogoutIconWithFrame: (CGRect)frame;
+ (void)drawLogOutButtonWithFrame: (CGRect)frame;
+ (void)drawTOS_ButtonWithFrame: (CGRect)frame;
+ (void)drawContactsIcon;
+ (void)drawAddIcon;
+ (void)drawTrashButtonWithOuterFrame: (CGRect)outerFrame selectWithDeleteColor: (BOOL)selectWithDeleteColor;
+ (void)drawPlay_PauseWithFrame: (CGRect)frame playPauseDisplaysPlay: (BOOL)playPauseDisplaysPlay;
+ (void)drawCanvas3WithFrame: (CGRect)frame;
+ (void)drawEmailIcon;
+ (void)drawBack_buttonWithBack_ButtonFrame: (CGRect)back_ButtonFrame;
+ (void)drawCanvas6WithFrame: (CGRect)frame;
+ (void)drawMessageIcon;
+ (void)drawMoreIcon;
+ (void)drawCanvas9WithFrame: (CGRect)frame;
+ (void)drawSearchIconWithFrame: (CGRect)frame;
+ (void)drawStarIconWithFrame: (CGRect)frame;
+ (void)drawCanvas12WithFrame: (CGRect)frame;
+ (void)drawTypingIconWithFrame: (CGRect)frame;
+ (void)drawUndoIconWithFrame: (CGRect)frame;
+ (void)drawDefaultAvatarIcon;

// Generated Images
+ (UIImage*)imageOfLeaveFeedback_ButtonWithFrame: (CGRect)frame;
+ (UIImage*)imageOfUpRight;
+ (UIImage*)imageOfUpLeft;
+ (UIImage*)imageOfDownRight;
+ (UIImage*)imageOfDownLeft;
+ (UIImage*)imageOfMoreLogin;
+ (UIImage*)imageOfDefaultAvatarLogin;
+ (UIImage*)imageOfVoicemailLogin;
+ (UIImage*)imageOfSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (UIImage*)imageOfVoicemailIcon;
+ (UIImage*)imageOfLogoutIconWithFrame: (CGRect)frame;
+ (UIImage*)imageOfLogOutButtonWithFrame: (CGRect)frame;
+ (UIImage*)imageOfContactsIcon;
+ (UIImage*)imageOfTrashButtonWithOuterFrame: (CGRect)outerFrame selectWithDeleteColor: (BOOL)selectWithDeleteColor;
+ (UIImage*)imageOfBack_buttonWithBack_ButtonFrame: (CGRect)back_ButtonFrame;
+ (UIImage*)imageOfCanvas6WithFrame: (CGRect)frame;
+ (UIImage*)imageOfMessageIcon;
+ (UIImage*)imageOfMoreIcon;
+ (UIImage*)imageOfCanvas9WithFrame: (CGRect)frame;
+ (UIImage*)imageOfSearchIconWithFrame: (CGRect)frame;
+ (UIImage*)imageOfStarIconWithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas12WithFrame: (CGRect)frame;
+ (UIImage*)imageOfTypingIconWithFrame: (CGRect)frame;
+ (UIImage*)imageOfUndoIconWithFrame: (CGRect)frame;
+ (UIImage*)imageOfDefaultAvatarIcon;

@end
