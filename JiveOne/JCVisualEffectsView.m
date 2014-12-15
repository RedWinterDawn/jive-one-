//
//  JCVisualEffectsView.m
//  JiveOne
//
//  Created by Robert Barclay on 12/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVisualEffectsView.h"
#import "FXBlurView.h"

@interface JCVisualEffectsView (){
    
}

@property (nonatomic, strong) UIView *visualEffectsView;

@end

@implementation JCVisualEffectsView

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    UIView *view = self.visualEffectsView;
    if (!view.superview) {
        view.frame = self.bounds;
        [super addSubview:view];
    }
}

#pragma mark - Getters -

-(UIView *)visualEffectsView
{
    if (!_visualEffectsView) {
        if ([UIVisualEffectView class]){
            _visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:[self systemEffectForEffect:self.effect]];
        }
        else
        {
            FXBlurView *blurView = [[FXBlurView alloc] init];
            blurView.blurRadius = 40;
            blurView.underlyingView = self.backgroundView;
            blurView.tintColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.2f];
            _visualEffectsView = blurView;
        }
    }
    return _visualEffectsView;
}

#pragma mark - Private -

/**
 * Returns based on our wrapper class the appropriate System Classes for the different effects.
 */
-(UIVisualEffect *)systemEffectForEffect:(JCVisualEffect *)effect
{
    if ([effect isKindOfClass:[JCVibrancyEffect class]])
    {
        JCBlurEffect *blurEffect = ((JCVibrancyEffect *)effect).blurEffect;
        UIBlurEffectStyle style = (UIBlurEffectStyle)((JCBlurEffect *)blurEffect).style;
        return [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:style]];
    }
    else if([effect isKindOfClass:[JCBlurEffect class]])
    {
        UIBlurEffectStyle style = (UIBlurEffectStyle)((JCBlurEffect *)effect).style;
        return [UIBlurEffect effectWithStyle:style];
    }
    return nil;
}

-(JCVisualEffect *)effect
{
    if (!_effect) {
        _effect = [JCBlurEffect effectWithStyle:JCBlurEffectStyleLight];
    }
    return _effect;
}

@end

@implementation JCVisualEffect

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] allocWithZone:zone];
}

@end


@implementation JCBlurEffect

+(JCBlurEffect *)effectWithStyle:(JCBlurEffectStyle)style
{
    JCBlurEffect *blurEffect = [[JCBlurEffect alloc] init];
    blurEffect.style = style;
    return blurEffect;
}

- (id)copyWithZone:(NSZone *)zone
{
    JCBlurEffect *blurEffect = [[self class] allocWithZone:zone];
    blurEffect.style = self.style;
    return blurEffect;
}

@end


@implementation JCVibrancyEffect

+(JCVibrancyEffect *)effectForBlurEffect:(JCBlurEffect *)blurEffect
{
    JCVibrancyEffect *vibrancyEffect = [[JCVibrancyEffect alloc] init];
    vibrancyEffect.blurEffect = blurEffect;
    return vibrancyEffect;
}

- (id)copyWithZone:(NSZone *)zone
{
    JCVibrancyEffect *vibrancyEffect = [[self class] allocWithZone:zone];
    vibrancyEffect.blurEffect = self.blurEffect;
    return vibrancyEffect;
}

@end