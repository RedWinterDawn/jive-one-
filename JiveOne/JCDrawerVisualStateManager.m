//
//  JCDrawerVisualStateManager.m
//  JiveOne
//
//  Created by Robert Barclay on 2/3/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCDrawerVisualStateManager.h"

@implementation JCDrawerVisualStateManager

+ (instancetype)sharedManager {
    static JCDrawerVisualStateManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[JCDrawerVisualStateManager alloc] init];
        [_sharedManager setLeftDrawerAnimationType:JCDrawerAnimationTypeParallax];
        [_sharedManager setRightDrawerAnimationType:JCDrawerAnimationTypeParallax];
    });
    
    return _sharedManager;
}

-(MMDrawerControllerDrawerVisualStateBlock)drawerVisualStateBlockForDrawerSide:(MMDrawerSide)drawerSide{
    JCDrawerAnimationType animationType;
    if(drawerSide == MMDrawerSideLeft){
        animationType = self.leftDrawerAnimationType;
    }
    else {
        animationType = self.rightDrawerAnimationType;
    }
    
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock = nil;
    switch (animationType) {
        case JCDrawerAnimationTypeSlide:
            visualStateBlock = [MMDrawerVisualState slideVisualStateBlock];
            break;
        case JCDrawerAnimationTypeSlideAndScale:
            visualStateBlock = [MMDrawerVisualState slideAndScaleVisualStateBlock];
            break;
        case JCDrawerAnimationTypeParallax:
            visualStateBlock = [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:2.0];
            break;
        case JCDrawerAnimationTypeSwingingDoor:
            visualStateBlock = [MMDrawerVisualState swingingDoorVisualStateBlock];
            break;
        default:
            visualStateBlock =  ^(MMDrawerController * drawerController, MMDrawerSide drawerSide, CGFloat percentVisible){
                
                UIViewController * sideDrawerViewController;
                CATransform3D transform;
                CGFloat maxDrawerWidth;
                
                if(drawerSide == MMDrawerSideLeft){
                    sideDrawerViewController = drawerController.leftDrawerViewController;
                    maxDrawerWidth = drawerController.maximumLeftDrawerWidth;
                }
                else if(drawerSide == MMDrawerSideRight){
                    sideDrawerViewController = drawerController.rightDrawerViewController;
                    maxDrawerWidth = drawerController.maximumRightDrawerWidth;
                }
                
                if(percentVisible > 1.0){
                    transform = CATransform3DMakeScale(percentVisible, 1.f, 1.f);
                    
                    if(drawerSide == MMDrawerSideLeft){
                        transform = CATransform3DTranslate(transform, maxDrawerWidth*(percentVisible-1.f)/2, 0.f, 0.f);
                    }else if(drawerSide == MMDrawerSideRight){
                        transform = CATransform3DTranslate(transform, -maxDrawerWidth*(percentVisible-1.f)/2, 0.f, 0.f);
                    }
                }
                else {
                    transform = CATransform3DIdentity;
                }
                [sideDrawerViewController.view.layer setTransform:transform];
            };
            break;
    }
    return visualStateBlock;
}

@end
