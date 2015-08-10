//
//  JCDialerViewController.m
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneDialerViewController.h"
#import "JCAppSettings.h"
#import "JCPhoneNumberDataSource.h"
#import "JCContactCollectionViewCell.h"
#import "JCPhoneCallViewController.h"

NSString *const kJCDialerViewControllerCallerStoryboardIdentifier = @"InitiateCall";

@interface JCPhoneDialerViewController () <JCFormattedPhoneNumberLabelDelegate>
{
    BOOL _initiatingCall;
    
    NSArray *_phoneNumbers;
    UIFont *_font;
    UIColor *_color;
}

@property (nonatomic, strong) AFNetworkReachabilityManager *networkingReachabilityManager;
@property (nonatomic, strong) NSString *placeHolderText;

@end

@implementation JCPhoneDialerViewController

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
    self.backspaceButton.alpha = 0;
    
    _color = [UIColor darkTextColor];
    _font  = [UIFont systemFontOfSize:16];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateRegistrationStatus];
    _placeHolderText = NSLocalizedString(@"Enter Name or Number", @"Enter Name or Number");
    self.formattedPhoneNumberLabel.text = _placeHolderText;
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
    if (phoneManager.provisioningProfile && !phoneManager.isRegistered && !phoneManager.isRegistering) {
        [phoneManager connectWithProvisioningProfile:phoneManager.provisioningProfile];
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
        [self.phoneManager numberPadPressedWithInteger:button.tag];
        NSString *string = [[self class] characterFromNumPadTag:(int)button.tag];
        [self appendString:string];
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
    // If the string is empty, we populate the dial string with the most recent item in call history.
    NSString *dialString = self.formattedPhoneNumberLabel.dialString;
    JCPhoneManager *phoneManager = self.phoneManager;
    id<JCPhoneProvisioningDataSource> provisioningProfile = phoneManager.provisioningProfile;
    if (!dialString || [dialString isEqualToString:@""]) {
        id<JCPhoneNumberDataSource> phoneNumber = [phoneManager.delegate phoneManager:phoneManager lastCalledNumberForProvisioning:provisioningProfile];
        self.formattedPhoneNumberLabel.dialString = phoneNumber.number;
        return;
    }
    
    id<JCPhoneNumberDataSource> phoneNumber = [phoneManager.delegate phoneManager:phoneManager phoneNumberForNumber:dialString name:nil provisioning:provisioningProfile];
    if (phoneNumber) {
        if (_delegate && [_delegate respondsToSelector:@selector(phoneDialerViewController:shouldDialNumber:)]){
            [_delegate phoneDialerViewController:self shouldDialNumber:phoneNumber];
        }
        else {
            [self dialPhoneNumber:phoneNumber
              provisioningProfile:self.phoneManager.provisioningProfile
                           sender:sender
                       completion:^(BOOL success, NSError *error) {
                           if (success){
                               [self performSelector:@selector(clear:) withObject:sender afterDelay:1];
                           }
                       }];
        }
    }
}

-(IBAction)backspace:(id)sender
{
    [self appendString:nil];
    if ([self.formattedPhoneNumberLabel.text isEqualToString:@""]) {
        self.formattedPhoneNumberLabel.text = _placeHolderText;
    }
}

-(IBAction)clear:(id)sender
{
    [self.formattedPhoneNumberLabel clear];
    self.formattedPhoneNumberLabel.text = _placeHolderText;
    
    _phoneNumbers = nil;
    [self.collectionView reloadData];
}

-(IBAction)cancel:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(shouldCancelPhoneDialerViewController:)])
        [_delegate shouldCancelPhoneDialerViewController:self];
}

#pragma mark - Getters -

-(AFNetworkReachabilityManager *)networkingReacabilityManager
{
    if (!_networkingReachabilityManager) {
        _networkingReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _networkingReachabilityManager;
}

#pragma mark - Private -

- (id<JCPhoneNumberDataSource>)objectAtIndexPath:(NSIndexPath *)indexPath{
    return [_phoneNumbers objectAtIndex:indexPath.row];
}


-(void)appendString:(NSString *)string
{
    if (self.outputLabel) {
        self.outputLabel.text =  [NSString stringWithFormat:@"%@%@", self.outputLabel.text, string];
    } else {
        if (string == nil) {
            [self.formattedPhoneNumberLabel backspace];
        } else {
            [self.formattedPhoneNumberLabel append:string];
        }
    }
    
    if (self.collectionView) {
        [self updateCollectionView];
    }
}

- (void)updateCollectionView
{
    NSString *keyword = self.formattedPhoneNumberLabel.dialString;
    if (!keyword) {
        return;
    }
    
    JCPhoneManager *phoneManager = self.phoneManager;
    [phoneManager.delegate phoneManager:phoneManager phoneNumbersForKeyword:keyword provisioning:phoneManager.provisioningProfile completion:^(NSArray *phoneNumbers) {
        _phoneNumbers = phoneNumbers;
        [self.collectionView reloadData];
    }];
}

-(void)updateRegistrationStatus
{
    JCPhoneManager *phoneManager = self.phoneManager;
    JCAppSettings *appSettings = self.appSettings;
    AFNetworkReachabilityManager *reachabilityManager = self.networkingReachabilityManager;
    
    NSString *prompt = NSLocalizedStringFromTable(@"Unregistered", @"Phone", @"Registration Status Display");
    if (phoneManager.isRegistered) {
        self.callButton.selected = false;
        prompt = phoneManager.provisioningProfile.displayName;
    }
    else if (appSettings.wifiOnly && reachabilityManager.isReachableViaWWAN){
        prompt = NSLocalizedStringFromTable(@"Disabled", @"Phone", @"Registration Status Display");
    }
    else if (phoneManager.isRegistering) {
        prompt = NSLocalizedStringFromTable(@"Connecting", @"Phone", @"Registration Status Display");
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
    JCPhoneCallViewController *callViewController = self.phoneManager.callViewController;
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
    JCPhoneCallViewController *callViewController = self.phoneManager.callViewController;
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

#pragma mark - Delegate Handlers -

#pragma mark JCFormattedPhoneNumberLabelDelegate

-(void)didUpdateDialString:(NSString *)dialString
{
    __unsafe_unretained JCPhoneDialerViewController *weakSelf = self;
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _phoneNumbers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    JCContactCollectionViewCell *cell = (JCContactCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSString *keyword = self.formattedPhoneNumberLabel.dialString;
    id <JCPhoneNumberDataSource> personNumber = [self objectAtIndexPath:indexPath];
    cell.name.attributedText    = [personNumber titleTextWithKeyword:keyword font:_font color:_color];
    cell.number.attributedText  = [personNumber detailTextWithKeyword:keyword font:cell.number.font color:cell.number.textColor];
    return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JCPhoneNumberDataSource> phoneNumber = [self objectAtIndexPath:indexPath];
    JCPhoneManager *phoneManager = self.phoneManager;
    id <JCPhoneProvisioningDataSource> provisioningProfile = phoneManager.provisioningProfile;
    self.formattedPhoneNumberLabel.dialString = phoneNumber.dialableNumber;
    if (_delegate && [_delegate respondsToSelector:@selector(phoneDialerViewController:shouldDialNumber:)]) {
        [_delegate phoneDialerViewController:self shouldDialNumber:phoneNumber];
    }
    else {
        [self dialPhoneNumber:phoneNumber
          provisioningProfile:provisioningProfile
                       sender:collectionView
                   completion:^(BOOL success, NSError *error) {
                       if (success){
                           [self clear:nil];
                       }
                   }];
    }
}

@end


