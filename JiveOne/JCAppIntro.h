//
//  JCAppIntro.h
//  JiveOne
//
//  Created by Doug on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "IFTTTJazzHands.h"
#import "UIImage+ImageEffects.h"

@interface JCAppIntro : IFTTTAnimatedScrollViewController <IFTTTAnimatedScrollViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;

+ (id) sharedInstance;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;

@end
