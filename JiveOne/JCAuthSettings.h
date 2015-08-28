//
//  JCAuthenticationSettings.h
//  JiveOne
//
//  Created by Robert Barclay on 8/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JCPhoneModule/JCSettings.h>

@interface JCAuthSettings : JCSettings

@property (nonatomic) BOOL rememberMe;
@property (nonatomic, strong) NSString *rememberMeUser;

@end
