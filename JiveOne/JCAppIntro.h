//
//  JCAppIntro.h
//  JiveOne
//
//  Created by Doug on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "IFTTTJazzHands.h"
#import "UIImage+ImageEffects.h"
#import "JCStyleKitIcons.h"

@interface JCAppIntro : IFTTTAnimatedScrollViewController <IFTTTAnimatedScrollViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControlDots;
@property (weak, nonatomic) IBOutlet JCGetStartedButton *getStartedButton;

+ (id) sharedInstance;
@end
