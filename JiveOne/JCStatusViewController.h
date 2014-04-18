//
//  JCStatusViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCStatusViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *tokenLabel;
@property (weak, nonatomic) IBOutlet UILabel *socketStatusLabel;
@property (weak, nonatomic) IBOutlet UITextView *lastSocketEventTextView;
- (IBAction)refresh:(id)sender;
- (IBAction)poll:(id)sender;

@end
