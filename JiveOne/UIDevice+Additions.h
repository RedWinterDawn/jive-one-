//
//  UIDevice+Additions.h
//  JiveOne
//
//  Category Additions added to UIDevice to expose or provide additional data.
//
//  Created by Robert Barclay on 12/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Compatibility)

@property (nonatomic, readonly) BOOL iOS8;

+(BOOL)iOS8;

@end

@interface UIDevice (CellularData)

@property (nonatomic, readonly) BOOL canMakeCall;
@property (nonatomic, readonly) BOOL carrierAllowsVOIP;

-(BOOL)carrierAllowsVOIP;
-(BOOL)canMakeCall;

@end

@interface UIDevice (InstallationIdentifier)

@property (nonatomic, readonly) NSString *installationIdentifier;

-(void)clearInstallationIdentifier;
-(NSString *)userUniqueIdentiferForUser:(NSString *)username;

@end

@interface UIDevice (Platform)

@property (nonatomic, readonly) NSString *platform;
@property (nonatomic, readonly) NSString *platformType;

@end