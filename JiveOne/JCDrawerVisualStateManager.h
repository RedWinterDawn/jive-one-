//
//  JCDrawerVisualStateManager.h
//  JiveOne
//
//  Created by Robert Barclay on 2/3/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "MMDrawerVisualState.h"

typedef NS_ENUM(NSInteger, JCDrawerAnimationType){
    JCDrawerAnimationTypeNone,
    JCDrawerAnimationTypeSlide,
    JCDrawerAnimationTypeSlideAndScale,
    JCDrawerAnimationTypeSwingingDoor,
    JCDrawerAnimationTypeParallax,
};

@interface JCDrawerVisualStateManager : NSObject

@property (nonatomic,assign) JCDrawerAnimationType leftDrawerAnimationType;
@property (nonatomic,assign) JCDrawerAnimationType rightDrawerAnimationType;

+ (instancetype)sharedManager;

-(MMDrawerControllerDrawerVisualStateBlock)drawerVisualStateBlockForDrawerSide:(MMDrawerSide)drawerSide;

@end
