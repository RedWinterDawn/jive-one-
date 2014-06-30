//
//  JCStyleKit.h
//  JC
//
//  Created by Doug Leonard on 6/30/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface JCStyleKit : NSObject

// iOS Controls Customization Outlets
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* leaveFeedback_ButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* bottomLeftTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* bottomRightTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* topLeftTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* topRightTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* moreLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* defaultAvatarLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* voicemailLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* playLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* speakerLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* trashLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* scrubberLoginTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* voicemailCellTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* speakerButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* voicemailIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* logoutIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* logOutButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* contactsIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* trashButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* play_PauseTargets;
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
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* playPauseTextTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* scrubberTextTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* deleteTextTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* speakerTextTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* jiveLogoBlackTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* jiveLogoWhiteTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* getStartedButtonTargets;

// Colors
+ (UIColor*)unSelectedButtonColor;
+ (UIColor*)selectedButtonColor;
+ (UIColor*)deleteColor;
+ (UIColor*)loginColor;

// Drawing Methods
+ (void)drawTOS_ButtonWithFrame: (CGRect)frame;
+ (void)drawLeaveFeedback_ButtonWithFrame: (CGRect)frame;
+ (void)drawBottomLeft;
+ (void)drawBottomRight;
+ (void)drawTopLeft;
+ (void)drawTopRight;
+ (void)drawMoreLogin;
+ (void)drawDefaultAvatarLogin;
+ (void)drawVoicemailLogin;
+ (void)drawPlayLoginWithPlayPauseDisplaysPlay: (BOOL)playPauseDisplaysPlay;
+ (void)drawSpeakerLogin;
+ (void)drawTrashLogin;
+ (void)drawScrubberLogin;
+ (void)drawVoicemailCell;
+ (void)drawSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (void)drawComposeIconWithFrame: (CGRect)frame;
+ (void)drawVoicemailIcon;
+ (void)drawVoicemailIconWhiteWithFrame: (CGRect)frame;
+ (void)drawLogoutIconWithFrame: (CGRect)frame;
+ (void)drawLogOutButtonWithFrame: (CGRect)frame;
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
+ (void)drawPlayPauseTextWithFrame: (CGRect)frame;
+ (void)drawScrubberTextWithFrame: (CGRect)frame;
+ (void)drawDeleteTextWithFrame: (CGRect)frame;
+ (void)drawSpeakerTextWithFrame: (CGRect)frame;
+ (void)drawJiveLogoBlackWithFrame: (CGRect)frame;
+ (void)drawJiveLogoWhiteWithFrame: (CGRect)frame;
+ (void)drawGetStartedButtonWithFrame: (CGRect)frame;

// Generated Images
+ (UIImage*)imageOfLeaveFeedback_ButtonWithFrame: (CGRect)frame;
+ (UIImage*)imageOfBottomLeft;
+ (UIImage*)imageOfBottomRight;
+ (UIImage*)imageOfTopLeft;
+ (UIImage*)imageOfTopRight;
+ (UIImage*)imageOfMoreLogin;
+ (UIImage*)imageOfDefaultAvatarLogin;
+ (UIImage*)imageOfVoicemailLogin;
+ (UIImage*)imageOfPlayLoginWithPlayPauseDisplaysPlay: (BOOL)playPauseDisplaysPlay;
+ (UIImage*)imageOfSpeakerLogin;
+ (UIImage*)imageOfTrashLogin;
+ (UIImage*)imageOfScrubberLogin;
+ (UIImage*)imageOfVoicemailCell;
+ (UIImage*)imageOfSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (UIImage*)imageOfVoicemailIcon;
+ (UIImage*)imageOfLogoutIconWithFrame: (CGRect)frame;
+ (UIImage*)imageOfLogOutButtonWithFrame: (CGRect)frame;
+ (UIImage*)imageOfContactsIcon;
+ (UIImage*)imageOfTrashButtonWithOuterFrame: (CGRect)outerFrame selectWithDeleteColor: (BOOL)selectWithDeleteColor;
+ (UIImage*)imageOfPlay_PauseWithFrame: (CGRect)frame playPauseDisplaysPlay: (BOOL)playPauseDisplaysPlay;
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
+ (UIImage*)imageOfPlayPauseTextWithFrame: (CGRect)frame;
+ (UIImage*)imageOfScrubberTextWithFrame: (CGRect)frame;
+ (UIImage*)imageOfDeleteTextWithFrame: (CGRect)frame;
+ (UIImage*)imageOfSpeakerTextWithFrame: (CGRect)frame;
+ (UIImage*)imageOfJiveLogoBlackWithFrame: (CGRect)frame;
+ (UIImage*)imageOfJiveLogoWhiteWithFrame: (CGRect)frame;
+ (UIImage*)imageOfGetStartedButtonWithFrame: (CGRect)frame;

@end
