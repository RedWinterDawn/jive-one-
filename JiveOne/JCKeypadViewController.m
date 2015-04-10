//
//  JCKeyboardViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCKeypadViewController.h"

@implementation JCKeypadViewController

-(IBAction)numPadPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        self.outputLabel.text =  [NSString stringWithFormat:@"%@%@", self.outputLabel.text, [[self class] characterFromNumPadTag:(int)button.tag]];
        if (_delegate && [_delegate respondsToSelector:@selector(keypadViewController:didTypeNumber:)])
            [_delegate keypadViewController:self didTypeNumber:button.tag];
    }
}

@end
