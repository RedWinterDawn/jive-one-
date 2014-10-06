//
//  JCKeyboardViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"

@class JCKeyboardViewController;

@protocol JCKeyboardViewControllerDelegate <NSObject>

-(void)keyboardViewController:(JCKeyboardViewController *)controller didTypeNumber:(NSString *)typedNumber;

@end

@interface JCKeyboardViewController : JCDialerViewController

@property (nonatomic, weak) IBOutlet id <JCKeyboardViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UILabel *outputLabel;

@end
