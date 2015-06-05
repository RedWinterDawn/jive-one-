//
//  JCContactDetailTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactDetailController.h"

#import "JCPhoneManager.h"
#import "JCAuthenticationManager.h"

#import "Extension.h"
#import "InternalExtension.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"
#import "JCVoicemailNumber.h"
#import "JCPersonDataSource.h"

#import "JCDialerViewController.h"
#import "JCStoryboardLoaderViewController.h"

@implementation JCContactDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Handling calling from the view.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    JCPhoneManager *phoneManager = self.phoneManager;
    if (self.isTablet) {
        [center addObserver:self selector:@selector(onActiveCall) name:kJCPhoneManagerShowCallsNotification object:phoneManager];
        [center addObserver:self selector:@selector(onInactiveCall) name:kJCPhoneManagerHideCallsNotification object:phoneManager];
        if (phoneManager.isActiveCall) {
            [self onActiveCall];
        }
    }
    
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if (![phoneNumber isKindOfClass:[Extension class]]) {
        self.navigationItem.rightBarButtonItem =  self.editButtonItem;
        if (!phoneNumber) {
            [self setEditing:YES animated:NO];
        }
    }
    
    [self layoutForPhoneNumber:self.phoneNumber animated:NO];
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

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (!editing) {
        [self save];
    }
    
    [super setEditing:editing animated:animated];
}

-(void)setEditing:(BOOL)editing
{
    if (!editing) {
        [self save];
    }
    
    [super setEditing:editing];
}

#pragma mark - Private -

-(void)save
{
    NSLog(@"Save Sent");
    
    id<JCPhoneNumberDataSource> phoneNumber = self.phoneNumber;
    if ([phoneNumber isKindOfClass:[NSManagedObjectContext class]]) {
        
    } else {
        
    }
    
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)layoutForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber animated:(BOOL)animated
{
    // We can not edit Extensions.
    if ([phoneNumber isKindOfClass:[Extension class]])
    {
        [self layoutForExtension:(Extension *)phoneNumber];
        [self reloadDataAnimated:animated];
        return;
    }
    
    [self layoutNameSection:phoneNumber];
    self.numberCell.detailTextLabel.text = phoneNumber.formattedNumber;
    [self cell:self.numberCell setHidden:NO];
    
    [self reloadDataAnimated:animated];
}

-(void)layoutNameSection:(id<JCPhoneNumberDataSource>)phoneNumber
{
    // Hide all name section cells first, then determine base on class introspection and protocol
    // Which one to do first.
    [self cells:_nameSectionCells setHidden:YES];
    
    NSString *name = phoneNumber.titleText;
    self.title = name;
    self.navigationItem.title = name;
    if (phoneNumber && ![phoneNumber conformsToProtocol:@protocol(JCPersonDataSource)]) {
        self.nameCell.textField.text  = name;
        [self cell:_nameCell setHidden:NO];
        return;
    }
    
    // If we are an object that can be a person.
    id<JCPersonDataSource> person = (id<JCPersonDataSource>)phoneNumber;
    if (person.firstName) {
        self.firstNameCell.textField.text = person.firstName;
    }
    if (person.lastName) {
        self.lastNameCell.textField.text = person.lastName;
    }
    
    [self cell:_firstNameCell setHidden:NO];
    [self cell:_lastNameCell setHidden:NO];
}

-(void)layoutForExtension:(Extension *)extension
{
    
    self.nameCell.textField.text  = extension.titleText;
    [self cells:_nameSectionCells setHidden:YES];
    [self cell:_nameCell setHidden:NO];
    
    self.extensionCell.detailTextLabel.text = extension.number;
    [self cell:self.extensionCell setHidden:NO];
    if ([extension isKindOfClass:[InternalExtension class]]) {
        NSString *jiveId = ((InternalExtension *)extension).jiveUserId;
        if (jiveId) {
            self.jiveIdCell.detailTextLabel.text = jiveId;
            [self cell:self.jiveIdCell setHidden:NO];
        }
    }
    else if([extension isKindOfClass:[Line class]]) {
        self.jiveIdCell.detailTextLabel.text = ((Line *)extension).pbx.user.jiveUserId;
        [self cell:self.jiveIdCell setHidden:NO];
    }
}



@end
