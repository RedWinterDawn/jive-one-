//
//  JCVisualEffectsView.h
//  JiveOne
//
//  Created by Robert Barclay on 12/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, JCBlurEffectStyle) {
    JCBlurEffectStyleExtraLight,
    JCBlurEffectStyleLight,
    JCBlurEffectStyleDark
};

@interface JCVisualEffect : NSObject <NSCopying> @end//, NSSecureCoding> @end

/* UIBlurEffect will provide a blur that appears to have been applied to the content layered behind the UIVisualEffectView. Views added to the contentView of a blur visual effect are not blurred themselves. */
@interface JCBlurEffect : JCVisualEffect
+ (JCBlurEffect *)effectWithStyle:(JCBlurEffectStyle)style;

@property (nonatomic) JCBlurEffectStyle style;

@end

/* UIVibrancyEffect amplifies and adjusts the color of content layered behind the view, allowing content placed inside the contentView to become more vivid. It is intended to be placed over, or as a subview of, a UIVisualEffectView that has been configured with a UIBlurEffect. This effect only affects content added to the contentView. Because the vibrancy effect is color dependent, subviews added to the contentView need to be tintColorDidChange aware and must be prepared to update themselves accordingly. UIImageView will need its image to have a rendering mode of UIImageRenderingModeAlwaysTemplate to receive the proper effect.
 */
@interface JCVibrancyEffect : JCVisualEffect
+ (JCVibrancyEffect *)effectForBlurEffect:(JCBlurEffect *)blurEffect;

@property (nonatomic) JCBlurEffect *blurEffect;

@end

@interface JCVisualEffectsView : UIView //<NSSecureCoding>

@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, strong, readonly) UIView *contentView; // Do not add subviews directly to UIVisualEffectView, use this view instead.
@property (nonatomic, copy) JCVisualEffect *effect;
@end

