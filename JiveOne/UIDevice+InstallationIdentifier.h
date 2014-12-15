//
//  UIDevice+InstallationIdentifier.h
//  JiveOne
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (InstallationIdentifier)

@property (nonatomic, readonly) NSString *installationIdentifier;

-(void)clearInstallationIdentifier;

@end
