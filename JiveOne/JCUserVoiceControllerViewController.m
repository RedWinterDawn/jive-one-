//
//  JCUserVoiceControllerViewController.m
//  JiveOne
//
//  Created by P Leonard on 6/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCUserVoiceControllerViewController.h"
#import "UserVoice.h"

@implementation UVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //    UVConfig *config = [UVConfig configWithSite:@"uservoice.us.com:3000"];
    UVConfig *config = [UVConfig configWithSite:@"demo.uservoice.com"];
    [UserVoice initialize:config];
}

- (IBAction)launchUserVoice:(id)sender {
    [UserVoice presentUserVoiceInterfaceForParentViewController:self];
}

- (IBAction)launchForum:(id)sender {
    [UserVoice presentUserVoiceForumForParentViewController:self];
}

- (IBAction)launchIdeaForm:(id)sender {
    [UserVoice presentUserVoiceNewIdeaFormForParentViewController:self];
}

- (IBAction)launchTicketForm:(id)sender {
    [UserVoice presentUserVoiceContactUsFormForParentViewController:self];
}


@end
