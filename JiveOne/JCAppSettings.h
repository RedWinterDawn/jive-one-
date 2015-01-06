//
//  JCAppSettings.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kJCAppSettingsPreasenceAttribute;

@interface JCAppSettings : NSObject

@property (nonatomic, getter = isIntercomEnabled  ) BOOL intercomEnabled;
@property (nonatomic, getter = isWifiOnly              ) BOOL wifiOnly;
@property (nonatomic, getter = isPreasenceEnabled) BOOL preasenceEnabled;

@end

@interface JCAppSettings (Singleton)

+(instancetype)sharedSettings;

@end
