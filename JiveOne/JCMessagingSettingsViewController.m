//
//  JCMessagingSettingsViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 7/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessagingSettingsViewController.h"

#import "JCDIDSelectorViewController.h"
#import "PBX.h"
#import "DID.h"

@interface JCMessagingSettingsViewController () <JCDIDSelectorViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *smsUserDefaultNumber;
@property (weak, nonatomic) IBOutlet UITableViewCell *defaultDIDCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *blockedNumbersCell;

@end

@implementation JCMessagingSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateMessagingInfo];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *controller = segue.destinationViewController;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        controller = ((UINavigationController *)controller).topViewController;
    }
    
    if ([controller isKindOfClass:[JCDIDSelectorViewController class]]) {
        ((JCDIDSelectorViewController *)controller).delegate = self;
    }
}

-(void)didUpdateDIDSelectorViewController:(JCDIDSelectorViewController *)viewController
{
    [self updateMessagingInfo];
}

-(void)updateMessagingInfo
{
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    self.smsUserDefaultNumber.text  = authenticationManager.did.formattedNumber;
    PBX *pbx = authenticationManager.pbx;
    
    [self startUpdates];
    
    [self setCell:self.defaultDIDCell hidden:!pbx.sendSMSMessages];
    [self setCell:self.blockedNumbersCell hidden:!pbx.sendSMSMessages];
    
    [self endUpdates];
}

@end
