//
//  PresenceView.h
//  DrawingCellProperties
//
//  Created by Eduardo Gueiros on 3/11/14.
//  Copyright (c) 2014 Eduardo Gueiros. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface JCPresenceView : UIView

@property (nonatomic, assign) JCPresenceType presenceType;

@property (nonatomic) NSUInteger lineWidth;
@property (nonatomic) UIColor *baseColor;

@end
