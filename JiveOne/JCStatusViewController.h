//
//  JCStatusViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCStatusViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UILabel *tokenLabel;
@property (weak, nonatomic) IBOutlet UILabel *socketStatusLabel;
@property (weak, nonatomic) IBOutlet UITextView *lastSocketEventTextView;

#pragma mark - socket event subscriptions

@property (weak, nonatomic) IBOutlet UILabel *subscsription1;
@property (weak, nonatomic) IBOutlet UILabel *subscription2;
@property (weak, nonatomic) IBOutlet UILabel *subscription3;
@property (weak, nonatomic) IBOutlet UILabel *subscription4;
@property (weak, nonatomic) IBOutlet UILabel *subscription5;

@property (weak, nonatomic) IBOutlet UILabel *servername;
@property (weak, nonatomic) IBOutlet UILabel *reachability;




- (IBAction)refresh:(id)sender;
- (IBAction)poll:(id)sender;

@end
