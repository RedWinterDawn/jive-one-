//
//  JCStoryboardLoaderViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStoryboardLoaderViewController.h"

@interface JCStoryboardLoaderViewController ()
{
    UIViewController *_embeddedViewController;
}

@end

@implementation JCStoryboardLoaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIViewController *embeddedViewController = self.embeddedViewController;
    embeddedViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [embeddedViewController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self addChildViewController:embeddedViewController];
    [self.view addSubview:embeddedViewController.view];
}

-(UIViewController *)embeddedViewController
{
    if (!_embeddedViewController) {
        NSString *storyboardIdentifier = self.storyboardIdentifier;
        if (!storyboardIdentifier) {
            return nil;
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardIdentifier bundle:[NSBundle mainBundle]];
        if (!storyboard) {
            return nil;
        }
        _embeddedViewController = [storyboard instantiateInitialViewController];
    }
    return _embeddedViewController;
}


@end
