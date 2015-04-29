//
//  JCDialerViewController.m
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"

// Managers
#import "JCPhoneManager.h"
#import "JCAppSettings.h"

// Views
#import "JCContactCollectionViewCell.h"

// Categories
#import "NSString+Additions.h"

// Managed Objects
#import "OutgoingCall.h"
#import "LocalContact.h"

// Controllers
#import "JCCallerViewController.h"

NSString *const kJCDialerViewControllerCallerStoryboardIdentifier = @"InitiateCall";

@interface JCDialerViewController ()
{
    BOOL _initiatingCall;
    NSArray *_phoneNumbers;
}

@property (nonatomic, strong) AFNetworkReachabilityManager *networkingReachabilityManager;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation JCDialerViewController

/**
 * Override to get the Phone Manager and add observers to watch for connected status so we can display the registration 
 * state, we also set the views initial state for displaying state.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JCPhoneManager *phoneManager = self.phoneManager;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerRegisteredNotification object:phoneManager];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerUnregisteredNotification object:phoneManager];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerRegisteringNotification object:phoneManager];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerRegistrationFailureNotification object:phoneManager];
    
    if (self.isTablet) {
        [center addObserver:self selector:@selector(onActiveCall) name:kJCPhoneManagerShowCallsNotification object:phoneManager];
        [center addObserver:self selector:@selector(onInactiveCall) name:kJCPhoneManagerHideCallsNotification object:phoneManager];
        if (phoneManager.isActiveCall) {
            [self onActiveCall];
        }
    }
    
    [self updateRegistrationStatus];
    
    JCAddressBook *addressBook = self.phoneBook.addressBook;
    [center addObserver:self selector:@selector(updateCollectionView) name:kJCAddressBookLoadedNotification object:addressBook];
    
    self.backspaceButton.alpha = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateRegistrationStatus];    
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
#ifndef DEBUG
    self.navigationItem.rightBarButtonItem = nil;
#endif
}

/**
 * Override so that if the phone manager is not yet connected when the view appears, try to connect. If we are logged
 * out, or have network connectivity problems it will fail, otherwise we should succeed and register if we were not 
 * already registered.
 */
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    JCPhoneManager *phoneManager = self.phoneManager;
    if (phoneManager.line && !phoneManager.isRegistered && !phoneManager.isRegistering) {
        [phoneManager connectToLine:phoneManager.line];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IBActions -

/**
 * Tell the phone manager that a keypad number was pressed. Uses the tag property of the sender to identify which key, 
 * and the phone manager converts int into the DTMF tone for the phone.
 */
-(IBAction)numPadPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *button = (UIButton *)sender;
        [self appendString:[[self class] characterFromNumPadTag:(int)button.tag]];
        [self.phoneManager numberPadPressedWithInteger:button.tag];
    }
}

-(IBAction)numPadLogPress:(id)sender
{
    if ([sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
        UILongPressGestureRecognizer *gestureRecognizer = (UILongPressGestureRecognizer *)sender;
        UIView *view = gestureRecognizer.view;
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded && [view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            NSInteger tag = button.tag;
            switch (tag) {
                case 0:
                    [self appendString:@"+"];
                    break;
                    
                default:
                    break;
            }
        }
    }
}


-(IBAction)initiateCall:(id)sender
{
    NSString *string = self.formattedPhoneNumberLabel.dialString;
    Line *line = self.authenticationManager.line;
    
    // If the string is empty, we populate the dial string with the most recent item in call history.
    if (!string || [string isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@", line];
        OutgoingCall *call = [OutgoingCall MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:false inContext:self.context];
        self.formattedPhoneNumberLabel.dialString = call.number;
        return;
    }
    
    // Fetch the phone number.
    id<JCPhoneNumberDataSource> phoneNumber = [self.phoneBook phoneNumberForNumber:string name:nil forPbx:line.pbx excludingLine:line];
    [self dialPhoneNumber:phoneNumber
                usingLine:line
                   sender:sender
               completion:^(BOOL success, NSError *error) {
                   if (success){
                       [self clear:sender];
                   }
               }];
}

-(IBAction)backspace:(id)sender
{
    [self appendString:nil];
}

-(IBAction)clear:(id)sender
{
    [self.formattedPhoneNumberLabel clear];
    _phoneNumbers = nil;
    [self.collectionView reloadData];
}

#pragma mark - Getters -

-(NSManagedObjectContext *)context
{
    if (!_context) {
        _context = [NSManagedObjectContext MR_defaultContext];
    }
    return _context;
}

-(AFNetworkReachabilityManager *)networkingReacabilityManager
{
    if (!_networkingReachabilityManager) {
        _networkingReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _networkingReachabilityManager;
}

#pragma mark - Private -

-(void)appendString:(NSString *)string
{
    if (string == nil) {
        [self.formattedPhoneNumberLabel backspace];
    } else {
        [self.formattedPhoneNumberLabel append:string];
    }
    
    [self updateCollectionView];
}

-(void)updateCollectionView
{
    NSString *keyword = self.formattedPhoneNumberLabel.dialString;
    if (!keyword) {
        return;
    }
    
    Line *line = self.authenticationManager.line;
    [self.phoneBook phoneNumbersWithKeyword:keyword
                                    forLine:line
                                sortedByKey:NSStringFromSelector(@selector(name))
                                  ascending:YES
                                 completion:^(NSArray *phoneNumbers) {
                                     _phoneNumbers = phoneNumbers;
                                     [self.collectionView reloadData];
                                 }];
}

-(void)updateRegistrationStatus
{
    JCPhoneManager *phoneManager = self.phoneManager;
    JCAppSettings *appSettings = self.appSettings;
    AFNetworkReachabilityManager *reachabilityManager = self.networkingReachabilityManager;
    
    NSString *prompt = NSLocalizedString(@"Unregistered", nil);
    if (phoneManager.isRegistered) {
        self.callButton.selected = false;
        if (self.registrationStatusLabel) {
            prompt = phoneManager.line.number;
        }
        else {
            Line *line = phoneManager.line;
            prompt = line.displayName;
        }
    }
    else if (appSettings.wifiOnly && reachabilityManager.isReachableViaWWAN){
        prompt = NSLocalizedString(@"Disabled", nil);
    }
    else if (phoneManager.isRegistering) {
        prompt = NSLocalizedString(@"Connecting", nil);
    }
    else {
        self.callButton.selected = true;
    }
    
    if (self.registrationStatusLabel) {
        self.registrationStatusLabel.text = prompt;
    } else {
        self.title = prompt;
    }
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
    if (navigationController.topViewController == self) {
        callViewController.navigationItem.hidesBackButton = TRUE;
        [navigationController pushViewController:callViewController animated:NO];
        
    }
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

+(NSString *)characterFromNumPadTag:(NSInteger)tag
{
    switch (tag) {
        case 10:
            return @"*";
        case 11:
            return @"#";
        default:
            return [NSString stringWithFormat:@"%i", (int)tag];
    }
}

-(id <JCPersonDataSource>)objectAtIndexPath:(NSIndexPath *)indexPath{
    return [_phoneNumbers objectAtIndex:indexPath.row];
}

#pragma mark - Delegate Handlers -

#pragma mark JCFormattedPhoneNumberLabelDelegate

-(void)didUpdateDialString:(NSString *)dialString
{
    __unsafe_unretained JCDialerViewController *weakSelf = self;
    if (dialString.length == 0) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             weakSelf.backspaceButton.alpha = 0;
                         }
                         completion:NULL];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             weakSelf.backspaceButton.alpha = 1;
                         }
                         completion:NULL];
    }
}

#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _phoneNumbers.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JCPhoneNumberDataSource> personNumber = [self objectAtIndexPath:indexPath];
    JCContactCollectionViewCell *cell = (JCContactCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIColor *color = [UIColor darkTextColor];
    UIFont *font = [UIFont systemFontOfSize:16];
    
    NSString *keyword = self.formattedPhoneNumberLabel.dialString;
    cell.name.attributedText = [personNumber titleTextWithKeyword:keyword
                                                             font:font
                                                            color:color];
    
    cell.number.attributedText = [personNumber detailTextWithKeyword:keyword
                                                                font:cell.number.font
                                                               color:cell.number.textColor];
    return cell;
}

#pragma mark UICollectionViewDelegate
                                  
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JCPhoneNumberDataSource> personNumber = [self objectAtIndexPath:indexPath];
    self.formattedPhoneNumberLabel.dialString = personNumber.dialableNumber;
    [self dialPhoneNumber:personNumber
           usingLine:self.authenticationManager.line
              sender:collectionView
          completion:^(BOOL success, NSError *error) {
              if (success){
                  [self clear:nil];
              }
          }];
}

@end


