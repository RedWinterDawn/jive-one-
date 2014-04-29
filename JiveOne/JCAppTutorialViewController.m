//
//  JCAppTutorialViewController.m
//  JiveOne
//
//  Created by Doug on 4/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppTutorialViewController.h"

#define P(x,y) CGPointMake(x, y)

@interface JCAppTutorialViewController ()

//Views we can move.

@end


@implementation JCAppTutorialViewController

CALayer *car;
UIBezierPath* bezierPath;
CALayer* squareOne;
CALayer* squareTwo;
CALayer* squareThree;
UIBezierPath* bezierPathOne;
UIBezierPath* bezierPathTwo;
UIBezierPath* bezierPathThree;

CALayer* text;

CAShapeLayer *racetrack;
CAShapeLayer *track1;
CAShapeLayer *track2;
CAShapeLayer *track3;
float xCoord = 0.0;

double firstX;
double firstY;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //text
    text = [CALayer layer];
    text.bounds = CGRectMake(19, 36, 90, 90);
//    text.backgroundColor = [UIColor yellowColor].CGColor;
    CATextLayer *label = [[CATextLayer alloc]init];
    [label setFont:@"Helvetica-Bold"];
    [label setFontSize:20];
    [label setFrame:text.bounds];
    [label setString:@"Hello"];
    [label setAlignmentMode:kCAAlignmentCenter];
    [label setForegroundColor:[[UIColor blackColor] CGColor]];
    [text addSublayer:label];
    [self.view.layer addSublayer:text];
    
    //// Rectangle Drawing
    squareTwo = [CALayer layer];
	squareTwo.bounds = CGRectMake(118, 36, 90, 90);
    squareTwo.backgroundColor = [UIColor blueColor].CGColor;
	[self.view.layer addSublayer:squareTwo];
    
    squareThree = [CALayer layer];
	squareThree.bounds = CGRectMake(219, 36, 90, 90);
    squareThree.backgroundColor = [UIColor greenColor].CGColor;
	[self.view.layer addSublayer:squareThree];
    
    bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(297.5, 24.5)];
    [bezierPath addLineToPoint: CGPointMake(56.5, 185.5)];

    
    //// Bezier Drawing
    bezierPathOne = [UIBezierPath bezierPath];
    [bezierPathOne moveToPoint: CGPointMake(268.5, 80.5)];
    [bezierPathOne addCurveToPoint: CGPointMake(64.5, 193.5) controlPoint1: CGPointMake(315.94, 319) controlPoint2: CGPointMake(64.5, 193.5)];
    
    
    //// Bezier 2 Drawing
    bezierPathTwo = [UIBezierPath bezierPath];
    [bezierPathTwo moveToPoint: CGPointMake(166.5, 79.5)];
    [bezierPathTwo addCurveToPoint: CGPointMake(66.5, 481.5) controlPoint1: CGPointMake(430.94, 571) controlPoint2: CGPointMake(66.5, 481.5)];

    
    //// Bezier 3 Drawing
    bezierPathThree = [UIBezierPath bezierPath];
    [bezierPathThree moveToPoint: CGPointMake(58.5, 365.5)];
    [bezierPathThree addCurveToPoint: CGPointMake(253.5, 522.5) controlPoint1: CGPointMake(70.89, 362.13) controlPoint2: CGPointMake(158.84, 532.62)];
    [bezierPathThree addCurveToPoint: CGPointMake(266.5, 186.5) controlPoint1: CGPointMake(321.99, 515.18) controlPoint2: CGPointMake(274.98, 246.96)];
    [bezierPathThree addCurveToPoint: CGPointMake(58.5, 82.5) controlPoint1: CGPointMake(232.58, -55.33) controlPoint2: CGPointMake(58.5, 82.5)];

    track1 = [CAShapeLayer layer];
	track1.path = bezierPathOne.CGPath;
	track1.strokeColor = [UIColor blackColor].CGColor;
	track1.fillColor = [UIColor clearColor].CGColor;
	track1.lineWidth = 10.0;
	[self.view.layer addSublayer:track1];
    
    track2 = [CAShapeLayer layer];
	track2.path = bezierPathTwo.CGPath;
	track2.strokeColor = [UIColor blackColor].CGColor;
	track2.fillColor = [UIColor clearColor].CGColor;
	track2.lineWidth = 10.0;
	[self.view.layer addSublayer:track2];
    
    track3 = [CAShapeLayer layer];
	track3.path = bezierPathThree.CGPath;
	track3.strokeColor = [UIColor blackColor].CGColor;
	track3.fillColor = [UIColor clearColor].CGColor;
	track3.lineWidth = 10.0;
	[self.view.layer addSublayer:track3];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)panView:(UIPanGestureRecognizer *)gestureRecognizer {
    //UIView *piece = [gestureRecognizer view];
    
//    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gestureRecognizer translationInView:self.view ];
        
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim.path = bezierPath.CGPath;
        anim.rotationMode = kCAAnimationLinear;
        anim.speed = 0.0;
        anim.removedOnCompletion = YES;
        xCoord = xCoord + translation.x;
        anim.timeOffset = xCoord/3200;
        NSLog(@"%f : %f", translation.x, xCoord/3200 );
        anim.duration = 1.0;
        [text addAnimation:anim forKey:@"race"];
        
        
        CAKeyframeAnimation *anim2 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim2.path = bezierPathTwo.CGPath;
        anim2.rotationMode = kCAAnimationRotateAuto;
        anim2.speed = 0.0;
        anim2.removedOnCompletion = NO;
        anim2.timeOffset = xCoord/3200;
        anim2.duration = 1.0;
        [squareTwo addAnimation:anim2 forKey:@"race"];
        
        CAKeyframeAnimation *anim3 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim3.path = bezierPathThree.CGPath;
        anim3.rotationMode = kCAAnimationRotateAuto;
        anim3.speed = 0.0;
        anim3.removedOnCompletion = NO;
        anim3.timeOffset = xCoord/3200;
        anim3.duration = 1.0;
        [squareThree addAnimation:anim3 forKey:@"race"];
    }


    
    
}

@end
