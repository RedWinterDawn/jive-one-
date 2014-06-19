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
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas2Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas4Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas6Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas7Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas8Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas9Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas10Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas11Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas12Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas13Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas14Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas15Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* canvas16Targets;

// Drawing Methods
+ (void)drawSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (void)drawTrashButtonWithOuterFrame: (CGRect)outerFrame selectWithDeleteColor: (BOOL)selectWithDeleteColor;
+ (void)drawComposeIconWithFrame: (CGRect)frame;
+ (void)drawPlay_PauseWithFrame: (CGRect)frame playPauseDisplaysPlay: (BOOL)playPauseDisplaysPlay;
+ (void)drawCanvas1WithFrame: (CGRect)frame;
+ (void)drawCanvas3WithFrame: (CGRect)frame;
+ (void)drawCanvas5WithFrame: (CGRect)frame;
+ (void)drawCanvas2WithFrame: (CGRect)frame;
+ (void)drawCanvas4WithFrame: (CGRect)frame;
+ (void)drawCanvas6WithFrame: (CGRect)frame;
+ (void)drawCanvas7WithFrame: (CGRect)frame;
+ (void)drawCanvas8WithFrame: (CGRect)frame;
+ (void)drawCanvas9WithFrame: (CGRect)frame;
+ (void)drawCanvas10WithFrame: (CGRect)frame;
+ (void)drawCanvas11WithFrame: (CGRect)frame;
+ (void)drawCanvas12WithFrame: (CGRect)frame;
+ (void)drawCanvas13WithFrame: (CGRect)frame;
+ (void)drawCanvas14WithFrame: (CGRect)frame;
+ (void)drawCanvas15WithFrame: (CGRect)frame;
+ (void)drawCanvas16WithFrame: (CGRect)frame;

// Generated Images
+ (UIImage*)imageOfSpeakerButtonWithSpeakerFrame: (CGRect)speakerFrame speakerIsSelected: (BOOL)speakerIsSelected;
+ (UIImage*)imageOfTrashButtonWithOuterFrame: (CGRect)outerFrame selectWithDeleteColor: (BOOL)selectWithDeleteColor;
+ (UIImage*)imageOfCanvas2WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas4WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas6WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas7WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas8WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas9WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas10WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas11WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas12WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas13WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas14WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas15WithFrame: (CGRect)frame;
+ (UIImage*)imageOfCanvas16WithFrame: (CGRect)frame;

@end
