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

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    UIViewController *embeddedViewController = self.embeddedViewController;
    if (!embeddedViewController) {
        return;
    }
    
    embeddedViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [embeddedViewController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    embeddedViewController.view.frame = self.view.bounds;
    [self addChildViewController:embeddedViewController];
    [self.view addSubview:embeddedViewController.view];
    self.title = embeddedViewController.title;
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
        
        NSString *viewControllerIdentifier = self.viewControllerIdentifier;
        if (viewControllerIdentifier) {
            _embeddedViewController = [storyboard instantiateViewControllerWithIdentifier:viewControllerIdentifier];
        } else {
            _embeddedViewController = [storyboard instantiateInitialViewController];
        }
    }
    return _embeddedViewController;
}




@end
