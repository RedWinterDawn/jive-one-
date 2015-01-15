//
//  JCDebugPhoneManagerTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 1/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCDebugPhoneManagerTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *reachability;
@property (weak, nonatomic) IBOutlet UILabel *previousReachability;
@property (weak, nonatomic) IBOutlet UILabel *wifiOnly;

@property (weak, nonatomic) IBOutlet UILabel *networkType;
@property (weak, nonatomic) IBOutlet UILabel *connecting;
@property (weak, nonatomic) IBOutlet UILabel *connected;

@end
