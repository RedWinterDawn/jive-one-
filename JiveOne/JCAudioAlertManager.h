//
//  JCAlertManager.h
//  JiveOne
//
//  Created by P Leonard on 1/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface JCAudioAlertManager : NSObject

- (void)vibrate;            // Single vibrate.
- (void)startRepeatingVibration:(BOOL)repeating;

- (void)ring;               // Single ring.
- (void)startRepeatingRingtone:(BOOL)repeating;

- (void)stop;

@end
