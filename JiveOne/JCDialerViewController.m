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
    JCPhoneManager *_phoneManager;
    BOOL _initiatingCall;
    NSMutableArray *_contacts;
}

@end

@implementation JCDialerViewController

/**
 * Override to get the Phone Manager and add observers to watch for connected status so we can display the registration 
 * state, we also set the views initial state for displaying state.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _phoneManager = [JCPhoneManager sharedManager];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerRegisteredNotification object:_phoneManager];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerUnregisteredNotification object:_phoneManager];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerRegisteringNotification object:_phoneManager];
    [center addObserver:self selector:@selector(updateRegistrationStatus) name:kJCPhoneManagerRegistrationFailureNotification object:_phoneManager];
    [self updateRegistrationStatus];
    
    self.backspaceBtn.alpha = 0;
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
    
    if (_phoneManager.line && !_phoneManager.isRegistered && !_phoneManager.isRegistering) {
        [JCPhoneManager connectToLine:_phoneManager.line];
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
    NSString *string = self.dialStringLabel.dialString;
    
    // If the string is empty, we populate the dial string with the most recent item in call history.
    if (!string || [string isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@", _phoneManager.line];
        OutgoingCall *call = [OutgoingCall MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:false];
        self.dialStringLabel.dialString = call.number;
        return;
    }
    
    [self dialNumber:string
           usingLine:[JCAuthenticationManager sharedInstance].line
              sender:sender
          completion:^(BOOL success, NSError *error) {
              if (success){
                  self.dialStringLabel.dialString = nil;
              }
          }];
}

-(IBAction)backspace:(id)sender
{
    [self appendString:nil];
    
}

-(IBAction)clear:(id)sender
{
    [self.dialStringLabel clear];
    _contacts = nil;
    [self.collectionView reloadData];
}

#pragma mark - Private -

-(void)appendString:(NSString *)string
{
    if (string == nil) {
        [self.dialStringLabel backspace];
    } else {
        [self.dialStringLabel append:string];
    }
    
    _contacts = nil;
    [JCAddressBook fetchNumbersWithKeyword:self.dialStringLabel.dialString completion:^(NSArray *numbers, NSError *error) {
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
    if (_phoneManager.isRegistered) {
        _callBtn.selected = false;
        prompt = _phoneManager.line.extension;
    }
    else if ([JCAppSettings sharedSettings].wifiOnly && [AFNetworkReachabilityManager sharedManager].isReachableViaWWAN){
        prompt = NSLocalizedString(@"Disabled", nil);
    }
    else if (_phoneManager.isRegistering) {
        prompt = NSLocalizedString(@"Connecting", nil);
    }
    else {
        _callBtn.selected = true;
    }
    
    self.regestrationStatus.text = prompt;
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
                             weakSelf.backspaceBtn.alpha = 0;
                         }
                         completion:^(BOOL finished) {
     
                         }];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             weakSelf.backspaceBtn.alpha = 1;
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
        cell.number.attributedText = [addressBookNumber detailTextWithKeyword:self.dialStringLabel.dialString
                                                                         font:cell.number.font
                                                                        color:cell.number.textColor];
    }
    
    return cell;
}
                                  
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JCPersonDataSource> personNumber = [self objectAtIndexPath:indexPath];
    self.dialStringLabel.dialString = personNumber.number.numericStringValue;
    
    NSString *string = self.dialStringLabel.dialString;
    [self dialNumber:string
           usingLine:[JCAuthenticationManager sharedInstance].line
              sender:collectionView
          completion:^(BOOL success, NSError *error) {
              if (success){
                  self.dialStringLabel.dialString = nil;
                  _contacts = nil;
                  [self.collectionView reloadData];
              }
          }];
}

@end


