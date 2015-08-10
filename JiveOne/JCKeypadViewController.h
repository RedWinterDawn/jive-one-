//
//  JCKeyboardViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneDialerViewController.h"

@class JCKeypadViewController;

@protocol JCKeypadViewControllerDelegate <NSObject>

@optional
-(void)keypadViewController:(JCKeypadViewController *)controller didTypeNumber:(NSInteger)number;

@end

@interface JCKeypadViewController : JCPhoneDialerViewController

@property (nonatomic, weak) id <JCKeypadViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UILabel *outputLabel;

@end
