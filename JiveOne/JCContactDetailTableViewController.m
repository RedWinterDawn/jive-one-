//
//  JCContactDetailTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactDetailTableViewController.h"

#import "JCPhoneManager.h"
#import "JCAuthenticationManager.h"

#import "Extension.h"
#import "Contact.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"
#import "JCVoicemailNumber.h"

#import "JCDialerViewController.h"
#import "JCStoryboardLoaderViewController.h"

@implementation JCContactDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    JCPhoneManager *phoneManager = self.phoneManager;
    if (self.isTablet) {
        [center addObserver:self selector:@selector(onActiveCall) name:kJCPhoneManagerShowCallsNotification object:phoneManager];
        [center addObserver:self selector:@selector(onInactiveCall) name:kJCPhoneManagerHideCallsNotification object:phoneManager];
        if (phoneManager.isActiveCall) {
            [self onActiveCall];
        }
    }
    
    [self cell:self.nameCell setHidden:YES];
    [self cell:self.extensionCell setHidden:YES];
    [self cell:self.jiveIdCell setHidden:YES];
    
    id <JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (phoneNumber) {
        if (phoneNumber.titleText) {
            self.title = phoneNumber.titleText;
            self.navigationItem.title = phoneNumber.titleText;
            self.nameCell.detailTextLabel.text  = phoneNumber.titleText;
            [self cell:self.nameCell setHidden:FALSE];
        }
        
        if ([phoneNumber isKindOfClass:[Extension class]]) {
            self.extensionCell.detailTextLabel.text = phoneNumber.number;
            [self cell:self.extensionCell setHidden:NO];
            
            if ([phoneNumber isKindOfClass:[Contact class]]) {
                NSString *jiveId = ((Contact *)phoneNumber).jiveUserId;
                if (jiveId) {
                    self.jiveIdCell.detailTextLabel.text = jiveId;
                    [self cell:self.jiveIdCell setHidden:NO];
                }
            }
            else if([phoneNumber isKindOfClass:[Line class]]) {
                self.jiveIdCell.detailTextLabel.text = ((Line *)phoneNumber).pbx.user.jiveUserId;
                [self cell:self.jiveIdCell setHidden:NO];
            }
        } else {
            self.extensionCell.textLabel.text = NSLocalizedString(@"Number", nil);
            self.extensionCell.detailTextLabel.text = phoneNumber.formattedNumber;
            [self cell:self.extensionCell setHidden:NO];
        }
    }
    [self reloadDataAnimated:NO];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)onActiveCall
{
    JCCallerViewController *callViewController = self.phoneManager.callViewController;
    if (!callViewController) {
        return;
    }
    
    // If we are the top view controller, we need to push the call view controller onto the view
    // controller stack.
    UINavigationController *navigationController = self.navigationController;
    callViewController.navigationItem.hidesBackButton = TRUE;
    [navigationController pushViewController:callViewController animated:NO];
}

-(void)onInactiveCall
{
    JCCallerViewController *callViewController = self.phoneManager.callViewController;
    if (!callViewController) {
        return;
    }
    
    UINavigationController *navigationController = self.navigationController;
    if (navigationController.topViewController != self) {
        [navigationController popToRootViewControllerAnimated:NO];
    }
}

-(IBAction)callExtension:(id)sender
{
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITableViewCell *cell = (UITableViewCell *)((UITapGestureRecognizer *)sender).view;
        if (cell == self.extensionCell) {
            [self dialPhoneNumber:self.phoneNumber
                        usingLine:self.authenticationManager.line
                           sender:sender];
        }
    }
}

@end
