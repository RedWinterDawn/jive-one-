//
//  JCDialerViewController.m
//  JiveOne
//
//  Created by P Leonard on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"
#import "JCPhoneManager.h"
#import "OutgoingCall.h"
#import "JCAppSettings.h"
#import "JCPhoneManagerError.h"
#import "JCPersonDataSource.h"
#import "JCAddressBook.h"
#import "JCAddressBookNumber.h"
#import "JCContactCollectionViewCell.h"

NSString *const kJCDialerViewControllerCallerStoryboardIdentifier = @"InitiateCall";

@interface JCDialerViewController ()
{
    BOOL _initiatingCall;
    NSMutableArray *_contacts;
}

@property (nonatomic, strong) JCAuthenticationManager *authenticationManager;
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
    [self updateRegistrationStatus];
    
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
        [JCPhoneManager connectToLine:phoneManager.line];
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
        [self appendString:[self characterFromNumPadTag:(int)button.tag]];
        [JCPhoneManager numberPadPressedWithInteger:button.tag];
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
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    
    // If the string is empty, we populate the dial string with the most recent item in call history.
    if (!string || [string isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@", authenticationManager.line];
        OutgoingCall *call = [OutgoingCall MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:false inContext:self.context];
        self.formattedPhoneNumberLabel.dialString = call.number;
        return;
    }
    
    [self dialNumber:string
           usingLine:authenticationManager.line
              sender:sender
          completion:^(BOOL success, NSError *error) {
              if (success){
                  self.formattedPhoneNumberLabel.dialString = nil;
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
    _contacts = nil;
    [self.collectionView reloadData];
}

#pragma mark - Getters -

-(JCAuthenticationManager *)authenticationManager
{
    if (!_authenticationManager) {
        _authenticationManager = [JCAuthenticationManager sharedInstance];
    }
    return _authenticationManager;
}

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
    
    _contacts = nil;
    
    [self.sharedAddressBook fetchNumbersWithKeyword:self.formattedPhoneNumberLabel.dialString completion:^(NSArray *numbers, NSError *error) {
        if (!error) {
            _contacts = numbers.mutableCopy;
        }
        
        
        if (!_contacts) {
            _contacts = [NSMutableArray array];
        }
        
        // TODO: Add in local contacts with a core data search here.
        //_contacts addObjectsFromArray:nil];
        [self.collectionView reloadData];
    }];
}

-(void)updateRegistrationStatus
{
    NSString *prompt = NSLocalizedString(@"Unregistered", nil);
    JCPhoneManager *phoneManager = self.phoneManager;
    if (phoneManager.isRegistered) {
        self.callButton.selected = false;
        prompt = phoneManager.line.extension;
    }
    else if (self.appSettings.wifiOnly && self.networkingReachabilityManager.isReachableViaWWAN){
        prompt = NSLocalizedString(@"Disabled", nil);
    }
    else if (phoneManager.isRegistering) {
        prompt = NSLocalizedString(@"Connecting", nil);
    }
    else {
        self.callButton.selected = true;
    }
    
    self.registrationStatusLabel.text = prompt;
}

-(NSString *)characterFromNumPadTag:(int)tag
{
    switch (tag) {
        case 10:
            return @"*";
        case 11:
            return @"#";
        default:
            return [NSString stringWithFormat:@"%i", tag];
    }
}

-(void)didUpdateDialString:(NSString *)dialString
{
    __unsafe_unretained JCDialerViewController *weakSelf = self;
    if (dialString.length == 0) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             weakSelf.backspaceButton.alpha = 0;
                         }
                         completion:^(BOOL finished) {
     
                         }];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             weakSelf.backspaceButton.alpha = 1;
                         }
                         completion:^(BOOL finished) {
     
                         }];
    }
}

-(id <JCPersonDataSource>)objectAtIndexPath:(NSIndexPath *)indexPath{
    return [_contacts objectAtIndex:indexPath.row];
}

#pragma mark - Delegate Handlers -

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _contacts.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JCPersonDataSource> personNumber = [self objectAtIndexPath:indexPath];
    JCContactCollectionViewCell *cell = (JCContactCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.name.text  = personNumber.name;
    
    if ([personNumber isKindOfClass:[JCAddressBookNumber class]]) {
        JCAddressBookNumber *addressBookNumber = (JCAddressBookNumber *)personNumber;
        cell.number.attributedText = [addressBookNumber detailTextWithKeyword:self.formattedPhoneNumberLabel.dialString
                                                                         font:cell.number.font
                                                                        color:cell.number.textColor];
    }
    
    return cell;
}
                                  
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JCPersonDataSource> personNumber = [self objectAtIndexPath:indexPath];
    self.formattedPhoneNumberLabel.dialString = personNumber.number.numericStringValue;
    
    NSString *string = self.formattedPhoneNumberLabel.dialString;
    [self dialNumber:string
           usingLine:self.authenticationManager.line
              sender:collectionView
          completion:^(BOOL success, NSError *error) {
              if (success){
                  self.formattedPhoneNumberLabel.dialString = nil;
                  _contacts = nil;
                  [self.collectionView reloadData];
              }
          }];
}

@end


