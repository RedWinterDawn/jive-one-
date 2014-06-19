//
//  JCStyleKit.h
//  JC
//
//  Created by Doug Leonard on 6/19/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>


@interface JCStyleKit : NSObject

// iOS Controls Customization Outlets
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* speakerButtonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* trashButtonTargets;

// Drawing Methods
+ (void)drawSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (void)drawTrashButtonWithOuterFrame: (CGRect)outerFrame selectWithDeleteColor: (BOOL)selectWithDeleteColor;
+ (void)drawComposeIconWithFrame: (CGRect)frame;
+ (void)drawPlay_PauseWithFrame: (CGRect)frame playPauseDisplaysPlay: (BOOL)playPauseDisplaysPlay;
+ (void)drawCanvas1;
+ (void)drawCanvas3;
+ (void)drawCanvas5;
+ (void)drawCanvas2;
+ (void)drawCanvas4;
+ (void)drawCanvas6;
+ (void)drawCanvas7;
+ (void)drawCanvas8;
+ (void)drawCanvas9;
+ (void)drawCanvas10;
+ (void)drawCanvas11;
+ (void)drawCanvas12;
+ (void)drawCanvas13;
+ (void)drawCanvas14;
+ (void)drawCanvas15;
+ (void)drawCanvas16;

// Generated Images
+ (UIImage*)imageOfSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (UIImage*)imageOfTrashButtonWithOuterFrame: (CGRect)outerFrame selectWithDeleteColor: (BOOL)selectWithDeleteColor;

@end
