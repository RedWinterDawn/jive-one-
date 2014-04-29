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
@property (weak, nonatomic) IBOutlet UIView *square1;
@property (weak, nonatomic) IBOutlet UIView *square2;
@property (weak, nonatomic) IBOutlet UIView *square3;
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
    
    //// Rectangle Drawing
    squareOne = [CALayer layer];
	squareOne.bounds = CGRectMake(19, 36, 90, 90);
    squareOne.backgroundColor = [UIColor magentaColor].CGColor;
	[self.view.layer addSublayer:squareOne];
    
    squareTwo = [CALayer layer];
	squareTwo.bounds = CGRectMake(118, 36, 90, 90);
    squareTwo.backgroundColor = [UIColor blueColor].CGColor;
	[self.view.layer addSublayer:squareTwo];
    
    squareThree = [CALayer layer];
	squareThree.bounds = CGRectMake(219, 36, 90, 90);
    squareThree.backgroundColor = [UIColor greenColor].CGColor;
	[self.view.layer addSublayer:squareThree];
    
    
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

    
    bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(166.85, 7.5)];
    [bezierPath addCurveToPoint: CGPointMake(82.86, 323.17) controlPoint1: CGPointMake(166.85, 7.5) controlPoint2: CGPointMake(-128.62, 195.4)];
    [bezierPath addCurveToPoint: CGPointMake(144.45, 478.5) controlPoint1: CGPointMake(294.34, 450.94) controlPoint2: CGPointMake(144.45, 478.5)];

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
    
    
//    racetrack = [CAShapeLayer layer];
//	racetrack.path = bezierPath.CGPath;
//	racetrack.strokeColor = [UIColor blackColor].CGColor;
//	racetrack.fillColor = [UIColor clearColor].CGColor;
//	racetrack.lineWidth = 10.0;
//	[self.view.layer addSublayer:racetrack];
//    
//    car = [CALayer layer];
//	car.bounds = CGRectMake(0, 0, 90, 90);
//	car.position = P(160, 325);
//    car.backgroundColor = [UIColor magentaColor].CGColor;
//	[self.view.layer addSublayer:car];
    
}
- (void)loadView{
    [super loadView];



    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)panView:(UIPanGestureRecognizer *)gestureRecognizer {
    //UIView *piece = [gestureRecognizer view];
    
    UIView *piece = self.square1;
//    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gestureRecognizer translationInView:[piece superview]];
        
        [piece setCenter:CGPointMake([piece center].x + translation.x, [piece center].y)];
        //[piece setCenter:CGPointMake([piece center].x + translation.x, [piece center].y + translation.y)];
        [gestureRecognizer setTranslation:CGPointZero inView:[piece superview]];
        
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim.path = bezierPath.CGPath;
        anim.rotationMode = kCAAnimationRotateAuto;
        //	anim.repeatCount = HUGE_VALF;
        anim.speed = 0.0;
        anim.removedOnCompletion = NO;
        xCoord = xCoord + translation.x;
        anim.timeOffset = xCoord/320;
        NSLog(@"%f : %f", translation.x, xCoord/320 );
        anim.duration = 1.0;
        [car addAnimation:anim forKey:@"race"];
        
        CAKeyframeAnimation *anim1 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim1.path = bezierPathOne.CGPath;
        anim1.rotationMode = kCAAnimationRotateAuto;
        anim1.speed = 0.0;
        anim1.removedOnCompletion = NO;
        anim1.timeOffset = xCoord/320;
        anim1.duration = 1.0;
        [squareOne addAnimation:anim1 forKey:@"race"];
        
        CAKeyframeAnimation *anim2 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim2.path = bezierPathTwo.CGPath;
        anim2.rotationMode = kCAAnimationRotateAuto;
        anim2.speed = 0.0;
        anim2.removedOnCompletion = NO;
        anim2.timeOffset = xCoord/320;
        anim2.duration = 1.0;
        [squareTwo addAnimation:anim2 forKey:@"race"];
        
        CAKeyframeAnimation *anim3 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim3.path = bezierPathThree.CGPath;
        anim3.rotationMode = kCAAnimationRotateAuto;
        anim3.speed = 0.0;
        anim3.removedOnCompletion = NO;
        anim3.timeOffset = xCoord/320;
        anim3.duration = 1.0;
        [squareThree addAnimation:anim3 forKey:@"race"];
    }


    
    
}

@end
