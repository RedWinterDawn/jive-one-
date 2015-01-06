//
//  JCAppSettings.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kJCAppSettingsPresenceAttribute;

@interface JCAppSettings : NSObject

@property (nonatomic, getter = isIntercomEnabled  ) BOOL intercomEnabled;
@property (nonatomic, getter = isWifiOnly              ) BOOL wifiOnly;
@property (nonatomic, getter = isPresenceEnabled) BOOL presenceEnabled;

@end

@interface JCAppSettings (Singleton)

+(instancetype)sharedSettings;

@end
