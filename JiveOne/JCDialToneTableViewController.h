//
//  JCDialToneTableViewController.h
//  JiveOne
//
//  Created by P Leonard on 6/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCStaticTableViewController.h"

@interface JCDialToneTableViewController : JCStaticTableViewController

@property (weak, nonatomic) IBOutlet UIView *routeIconBackground;
@property (weak, nonatomic) IBOutlet UISlider *volumeslidder;

@property (weak, nonatomic) IBOutlet UITableViewCell *ringtoneCell;
-(IBAction)sliderValue:(id)sender;


@end
