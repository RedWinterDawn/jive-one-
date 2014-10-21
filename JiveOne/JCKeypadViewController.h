//
//  JCKeyboardViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"

@class JCKeypadViewController;

@protocol JCKeypadViewControllerDelegate <NSObject>

-(void)keypadViewController:(JCKeypadViewController *)controller didTypeNumber:(NSString *)typedNumber;

@end

@interface JCKeypadViewController : JCDialerViewController

@property (nonatomic, weak) id <JCKeypadViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UILabel *outputLabel;

@end
