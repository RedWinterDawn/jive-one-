//
//  UIViewController+Additions.m
//  JiveOne
//
//  Created by Robert Barclay on 4/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "UIViewController+Additions.h"

@implementation UIViewController (Additions)

-(BOOL)isTablet
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

@end
