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
        NSString *typedChar = [self characterFromNumPadTag:(int)button.tag];
        self.outputLabel.text =  [NSString stringWithFormat:@"%@%@", self.outputLabel.text, typedChar];
        if (_delegate && [_delegate respondsToSelector:@selector(keypadViewController:didTypeNumber:)])
            [_delegate keypadViewController:self didTypeNumber:typedChar];
        else if (_delegate && [_delegate respondsToSelector:@selector(keypadViewController:didTypeDTMF:)])
            [_delegate keypadViewController:self didTypeDTMF:[self dtmfFromString:typedChar]];
    }
}

-(char)dtmfFromString:(NSString *)string
{
    NSInteger tag = [string integerValue];
    char dtmf = tag;
    switch (tag) {
        case kTAGStar:
        {
            dtmf = 10;
            break;
        }
        case kTAGSharp:
        {
            dtmf = 11;
            break;
        }
    }

    return dtmf;
}

@end
