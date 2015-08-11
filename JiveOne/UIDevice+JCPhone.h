//
//  UIDevice+JCPhone.h
//  JiveOne
//
//  Created by Robert Barclay on 8/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface UIDevice (JCPhone)

@property (nonatomic, readonly) BOOL canMakeCall;
@property (nonatomic, readonly) BOOL carrierAllowsVOIP;
@property (nonatomic, readonly) NSString *defaultCarrier;
@property (nonatomic, readonly) NSString *carrierIsoCountryCode;

@end
