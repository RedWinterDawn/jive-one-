//
//  JCPage1ViewController.m
//  JiveOne
//
//  Created by Doug on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPage1ViewController.h"

@interface JCPage1ViewController ()
@property (strong,nonatomic) UIDynamicAnimator* animator;
@property (strong, nonatomic) UILabel* headingLabel2;
@end

@implementation JCPage1ViewController

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
    
    

//    UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 240, 300, 30)];
//    headingLabel.text = @"Welcome to JiveApp";
//    headingLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];
//    
//    self.headingLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(100, 290, 300, 30)];
//    self.headingLabel2.text = @"Really Cool Feature";
//    self.headingLabel2.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];
//    [self.view addSubview:self.headingLabel2];
//    
//    [self.view addSubview:headingLabel];
//    CGPoint anchor;
//    anchor = CGPointMake(100, 290);
//    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
//    self.attachment = [[UIAttachmentBehavior alloc] initWithItem:self.headingLabel2 attachedToAnchor:anchor];
//    [self.animator addBehavior:self.attachment];
//    
}

#pragma mark - pageDelegateMethods

- (void)scrollingDidChangePullOffset:(CGFloat)offset
{
    
}

- (NSInteger)index{
    return 0;
}


-(UIDynamicAnimator*)animator{
    if (!_animator) {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }
    return _animator;
}

- (UIDynamicBehavior *)attachment
{
//    if(!_attachment){
//        _attachment = [[UIAttachmentBehavior alloc] initWithItem:self.headingLabel2 attachedToAnchor:anchor];
//        [self.animator addBehavior:self.attachment];
//    }
    return _attachment;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
