//
//  JCKeyboardViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCKeyboardViewController.h"

@implementation JCKeyboardViewController

-(IBAction)numPadPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        NSString *typedChar = [self characterFromNumPadTag:button.tag];
        
        if (_delegate && [_delegate respondsToSelector:@selector(keyboardViewController:didTypeNumber:)])
            [_delegate keyboardViewController:self didTypeNumber:typedChar];
        
        self.outputLabel.text =  [NSString stringWithFormat:@"%@%@", self.outputLabel.text, typedChar];
    }
}

@end
