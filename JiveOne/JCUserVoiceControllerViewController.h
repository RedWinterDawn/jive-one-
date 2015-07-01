//
//  JCUserVoiceControllerViewController.h
//  JiveOne
//
//  Created by P Leonard on 6/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface UVViewController : UIViewController
@property (weak, nonatomic) NSString *user;
@property (weak, nonatomic) NSString *uuid;
@property (weak, nonatomic) NSString *line;
@property (weak, nonatomic) NSString *domain;
@property (weak, nonatomic) NSString *model;
@property (weak, nonatomic) NSString *pbx;
@property (weak, nonatomic) NSString *carrier;


- (IBAction)launchUserVoice:(id)sender;
- (IBAction)launchForum:(id)sender;
- (IBAction)launchIdeaForm:(id)sender;
- (IBAction)launchTicketForm:(id)sender;

@end
