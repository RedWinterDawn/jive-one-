//
//  UIDevice+CellularData.h
//  JiveOne
//
//  Created by Robert Barclay on 12/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (CellularData)

@property (nonatomic, readonly) BOOL canMakeCall;
@property (nonatomic, readonly) BOOL carrierAllowsVOIP;

-(BOOL)carrierAllowsVOIP;

-(BOOL)canMakeCall;

@end
