//
//  JCPopoverSlider.h
//  JiveOne
//
//  Created by Doug on 5/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCPopoverSlider : UISlider

// Configurable Properties.
@property (nonatomic) CGFloat trackHeight;
@property (nonatomic) CGFloat thumbBorderWidth;
@property (nonatomic) CGFloat thumbDiameter;

@property (nonatomic, readonly) NSString *formattedValue;

@end
