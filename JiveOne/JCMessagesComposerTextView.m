//
//  JCMessagesComposerTextView.m
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessagesComposerTextView.h"

@implementation JCMessagesComposerTextView

-(void)awakeFromNib {
    
    [super awakeFromNib];
    
    // Jive Customizations.
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.layer.borderWidth = 0;
    self.backgroundColor = [UIColor clearColor];
}

@end
