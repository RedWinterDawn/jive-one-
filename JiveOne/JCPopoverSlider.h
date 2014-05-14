//
//  JCPopoverSlider.h
//  JiveOne
//
//  Created by Doug on 5/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPopoverView.h"

@interface JCPopoverSlider : UISlider

@property (strong, nonatomic) JCPopoverView *popupView;
@property (nonatomic, readonly) CGRect thumbRect;

@end
