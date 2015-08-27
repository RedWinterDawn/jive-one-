//
//  JCDebugTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDebugTableViewController.h"

#import "User.h"
#import "Line.h"
#import "DID.h"
#import "LineConfiguration.h"
#import "RecentEvent.h"
#import "MissedCall.h"
#import "Voicemail.h"
#import "PBX.h"
#import "InternalExtension.h"
#import "InternalExtensionGroup.h"

@interface JCDebugTableViewController ()

@end

@implementation JCDebugTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCAuthManager *authenticationManager = self.authenticationManager;
    self.jiveUserId.text = authenticationManager.user.jiveUserId;
    self.accessToken.text = authenticationManager.authInfo.accessToken;
    
    UIDevice *device = [UIDevice currentDevice];
    self.installationIdentifer.text = device.installationIdentifier;
    self.uuid.text = [device userUniqueIdentiferForUser:authenticationManager.user.jiveUserId];
    
    self.users.text                 = [NSString stringWithFormat:@"%lu", (unsigned long)[User MR_countOfEntities]];
    self.pbxs.text                  = [NSString stringWithFormat:@"%lu", (unsigned long)[PBX MR_countOfEntities]];
    self.lines.text                 = [NSString stringWithFormat:@"%lu", (unsigned long)[Line MR_countOfEntities]];
    self.dids.text                  = [NSString stringWithFormat:@"%lu", (unsigned long)[DID MR_countOfEntities]];
    
    self.lineConfigurations.text    = [NSString stringWithFormat:@"%lu", (unsigned long)[LineConfiguration MR_countOfEntities]];
    self.events.text                = [NSString stringWithFormat:@"%lu", (unsigned long)[RecentEvent MR_countOfEntities]];
    self.missed.text                = [NSString stringWithFormat:@"%lu", (unsigned long)[MissedCall MR_countOfEntities]];
    self.voicemails.text            = [NSString stringWithFormat:@"%lu", (unsigned long)[Voicemail MR_countOfEntities]];
    
    self.contacts.text              = [NSString stringWithFormat:@"%lu", (unsigned long)[InternalExtension MR_countOfEntities]];
    self.contactGroups.text         = [NSString stringWithFormat:@"%lu", (unsigned long)[InternalExtensionGroup MR_countOfEntities]];
}

@end
