//
//  JCAppIntro.m
//  JiveOne
//
//  Created by Doug on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppIntro.h"
#import "JCStyleKit.h"

#define NUMBER_OF_PAGES 4
#define timeForPage(page) (NSInteger)(self.view.frame.size.width * (page - 1))

@interface JCAppIntro ()

@property (strong, nonatomic) UIImageView *voicemailCell;
@property (strong, nonatomic) UIImageView *bottomRight;
@property (strong, nonatomic) UIImageView *bottomLeft;
@property (strong, nonatomic) UIImageView *topRight;
@property (strong, nonatomic) UIImageView *topLeft;
@property (strong, nonatomic) UIImageView *wordmark;
@property (strong, nonatomic) UILabel *lastLabel;
@property (strong, nonatomic) UILabel *firstLabel;

@end

@implementation JCAppIntro

- (id)init
{
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollView.contentSize = CGSizeMake(NUMBER_OF_PAGES * CGRectGetWidth(self.view.frame),
                                             CGRectGetHeight(self.view.frame));
    NSLog(@"### Content Size: %@", NSStringFromCGSize(self.scrollView.contentSize));

    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.animator = [IFTTTAnimator new];
    [self.scrollView addSubview:self.dismissButton];

    [self placeViews];
    [self configureAnimation];
    
}

- (void)placeViews
{
    //Add voicemailCell to center of page1
    self.voicemailCell = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"VoicemailCell.png"]];
    self.voicemailCell.center = self.view.center;
    self.voicemailCell.frame = CGRectMake(21, 200, 278, 157);
    [self.scrollView addSubview:self.voicemailCell];

    //TODO: Remove this
    self.wordmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main-logo.png"]];
    self.wordmark.center = self.view.center;
    self.wordmark.frame = CGRectOffset(
                                       self.wordmark.frame,
                                       self.view.frame.size.width,
                                       -10
                                       );
    [self.scrollView addSubview:self.wordmark];
    
    //add bottomRight to page2
    self.bottomRight = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfBottomRight]];
    self.bottomRight.center = self.view.center;
    self.bottomRight.frame = CGRectOffset(
                                      self.bottomRight.frame,
                                      self.view.frame.size.width + 70,
                                      90
                                      );
    [self.scrollView addSubview:self.bottomRight];

    //add bottomLeft to page2
    self.bottomLeft = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfBottomLeft]];
    self.bottomLeft.center = self.view.center;
    self.bottomLeft.frame = CGRectOffset(
                                      self.bottomLeft.frame,
                                      self.view.frame.size.width - 50,
                                      110
                                      );
    [self.scrollView addSubview:self.bottomLeft];
    
    //add topLeft to page2
    self.topLeft = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfTopLeft]];
    self.topLeft.center = self.view.center;
    self.topLeft.frame = CGRectOffset(
                                      self.topLeft.frame,
                                      self.view.frame.size.width - 0,
                                      -55
                                      );
    [self.scrollView addSubview:self.topLeft];
    
    //add topRight to page2
    self.topRight = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfTopRight]];
    self.topRight.center = self.view.center;
    self.topRight.frame = CGRectOffset(
                                      self.topRight.frame,
                                      self.view.frame.size.width -10,
                                      -90
                                      );
    [self.scrollView addSubview:self.topRight];
    
    //add firstLable to center of page1
    self.firstLabel = [[UILabel alloc] init];
    self.firstLabel.text = @"Introducing The Jive Voicemail App";
    [self.firstLabel sizeToFit];
    self.firstLabel.center = self.view.center;
    self.wordmark.frame = CGRectOffset(
                                       self.firstLabel.frame,
                                       self.view.frame.size.width,
                                       100
                                       );
    [self.scrollView addSubview:self.firstLabel];
    
    UILabel *secondPageText = [[UILabel alloc] init];
    secondPageText.text = @"It's really cool... have a look inside!";
    [secondPageText sizeToFit];
    secondPageText.center = self.view.center;
    secondPageText.frame = CGRectOffset(secondPageText.frame, timeForPage(2), 180);
    [self.scrollView addSubview:secondPageText];
    
    UILabel *thirdPageText = [[UILabel alloc] init];
    thirdPageText.text = @"You can check your voicemail";
    [thirdPageText sizeToFit];
    thirdPageText.center = self.view.center;
    thirdPageText.frame = CGRectOffset(thirdPageText.frame, timeForPage(3), -100);
    [self.scrollView addSubview:thirdPageText];
    
    UILabel *fourthPageText = [[UILabel alloc] init];
    fourthPageText.text = @"Dismiss";
    [fourthPageText sizeToFit];
    fourthPageText.center = self.view.center;
    fourthPageText.frame = CGRectOffset(fourthPageText.frame, timeForPage(4), 0);
    [self.scrollView addSubview:fourthPageText];

    self.lastLabel = fourthPageText;
    
    
    self.dismissButton.frame = CGRectOffset(self.dismissButton.frame, timeForPage(4), 0);
}

- (void)configureAnimation
{
    CGFloat dy = 240;
    
    // apply a 3D zoom animation to the first label
    IFTTTTransform3DAnimation * labelTransform = [IFTTTTransform3DAnimation animationWithView:self.firstLabel];
    IFTTTTransform3D *tt1 = [IFTTTTransform3D transformWithM34:0.03f];
    IFTTTTransform3D *tt2 = [IFTTTTransform3D transformWithM34:0.3f];
    tt2.rotate = (IFTTTTransform3DRotate){ -(CGFloat)(M_PI), 1, 0, 0 };
    tt2.translate = (IFTTTTransform3DTranslate){ 0, 0, 50 };
    tt2.scale = (IFTTTTransform3DScale){ 1.f, 2.f, 1.f };
    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(0)
                                                                andAlpha:1.0f]];
    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1)
                                                          andTransform3D:tt1]];
    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1.5)
                                                          andTransform3D:tt2]];
    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1.5) + 1
                                                                andAlpha:0.0f]];
    [self.animator addAnimation:labelTransform];
    
    // let's animate the wordmark
    IFTTTFrameAnimation *wordmarkFrameAnimation = [IFTTTFrameAnimation animationWithView:self.wordmark];
    [self.animator addAnimation:wordmarkFrameAnimation];
    
    [wordmarkFrameAnimation addKeyFrames:@[
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:CGRectOffset(self.wordmark.frame, 200, 0)],
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.wordmark.frame],
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.wordmark.frame, self.view.frame.size.width, dy)],
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andFrame:CGRectOffset(self.wordmark.frame, 0, dy)],
                                           ]];
    
    // Rotate a full circle from page 2 to 3
    IFTTTAngleAnimation *wordmarkRotationAnimation = [IFTTTAngleAnimation animationWithView:self.wordmark];
    [self.animator addAnimation:wordmarkRotationAnimation];
    [wordmarkRotationAnimation addKeyFrames:@[
                                              [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAngle:0.0f],
                                              [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAngle:(CGFloat)(2 * M_PI)],
                                              ]];
    
    // now, we animate the voicemailCell
    IFTTTFrameAnimation *voicemailCellFrameAnimation = [IFTTTFrameAnimation animationWithView:self.voicemailCell];
    [self.animator addAnimation:voicemailCellFrameAnimation];
    
    // the higher this number is the more the objects shrink
    CGFloat ds = 0;
    
    // move down and to the right, and shrink between pages 2 and 3
    [voicemailCellFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:self.voicemailCell.frame]];

    [voicemailCellFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2)
                                                                       andFrame:CGRectOffset(self.voicemailCell.frame, timeForPage(2), 0)]];
    // Animate the arrows ontop of voicemailcell in page2
    
    IFTTTFrameAnimation *bottomRightFrameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomRight];
    [self.animator addAnimation:bottomRightFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.bottomRight.frame]];
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3)
                                                                       andFrame:CGRectOffset(CGRectInset(self.bottomRight.frame, ds, ds), timeForPage(2), dy)]];
    // now, we animate the bottomLeft
    IFTTTFrameAnimation *bottomLeftFrameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomLeft];
    [self.animator addAnimation:bottomLeftFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.bottomLeft.frame]];
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3)
                                                                       andFrame:CGRectOffset(CGRectInset(self.bottomLeft.frame, ds, ds), timeForPage(2), dy)]];
    // now, we animate the topLeft
    IFTTTFrameAnimation *topLeftFrameAnimation = [IFTTTFrameAnimation animationWithView:self.topLeft];
    [self.animator addAnimation:topLeftFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.topLeft.frame]];
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3)
                                                                       andFrame:CGRectOffset(CGRectInset(self.topLeft.frame, ds, ds), timeForPage(2), dy)]];
    // now, we animate the topRight
    IFTTTFrameAnimation *topRightFrameAnimation = [IFTTTFrameAnimation animationWithView:self.topRight];
    [self.animator addAnimation:topRightFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.topRight.frame]];
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3)
                                                                       andFrame:CGRectOffset(CGRectInset(self.topRight.frame, ds, ds), timeForPage(2), dy)]];
    
    
    
    
    
    
//    // fade the unicorn in on page 2 and out on page 4
//    IFTTTAlphaAnimation *unicornAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.unicorn];
//    [self.animator addAnimation:unicornAlphaAnimation];
//    
//    [unicornAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
//    [unicornAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
//    [unicornAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
//    [unicornAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
//    
    // Fade out the label by dragging on the last page
    IFTTTAlphaAnimation *labelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.lastLabel];
    [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:1.0f]];
    [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4.35f) andAlpha:0.0f]];
    [self.animator addAnimation:labelAlphaAnimation];
}

#pragma mark - IFTTTAnimatedScrollViewControllerDelegate

- (void)animatedScrollViewControllerDidScrollToEnd:(IFTTTAnimatedScrollViewController *)animatedScrollViewController
{
    NSLog(@"Scrolled to end of scrollview!");
    NSLog(@"%f,%f",self.dismissButton.frame.origin.x,self.dismissButton.frame.origin.y);
}

- (void)animatedScrollViewControllerDidEndDraggingAtEnd:(IFTTTAnimatedScrollViewController *)animatedScrollViewController
{
    NSLog(@"Ended dragging at end of scrollview!");
}

- (IBAction)dismissButtonWasPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AppTutorialDismissed" object:nil];
    }];
    //Register for PushNotifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
}



@end
