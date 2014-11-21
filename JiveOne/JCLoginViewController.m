//
//  JCLoginViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLoginViewController.h"
#import "JCAuthenticationManager.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Common.h"
#import "Company.h"
#import <MBProgressHUD.h>
#import "JCStyleKit.h"
#import "JCV5ApiClient.h"
#import "JCV4ProvisioningClient.h"
#import "JCAppIntro.h"
#import "UIImage+ImageEffects.h"
#import "UITextField+ELFixSecureTextFieldFont.h"
#import "Lines+Custom.h"
#import "JCLineSelectorViewController.h"
#import <XMLDictionary/XMLDictionary.h>

@interface JCLoginViewController () <NSFileManagerDelegate>
{
	BOOL loginCanceled;
    MBProgressHUD *hud;
    
    JCAuthenticationManager *_authenticationManager;
}

@property (nonatomic, strong) NSError *errorOccurred;
@property (nonatomic, strong) NSTimer *loginTimer;

@end

@implementation JCLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.passwordTextField fixSecureTextFieldFont];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    _authenticationManager = [JCAuthenticationManager sharedInstance];
    
    [center addObserver:self selector:@selector(refreshAuthenticationCredentialsFailed:) name:kAuthenticationFromTokenFailed object:nil];
    [center addObserver:self selector:@selector(refreshAuthenticationCredentialsFailed:) name:kAuthenticationFromTokenFailedWithTimeout object:nil];
    [center addObserver:self selector:@selector(authenticated:) name:kAuthenticationFromTokenSucceeded object:nil];
    
    [center addObserver:self selector:@selector(userMinimumDataLoaded:) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:_authenticationManager];
    
    self.usernameTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.usernameTextField.layer.borderWidth = 1.0f;
    
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.usernameTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    
    self.passwordTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.passwordTextField.layer.borderWidth = 1.0f;
    
    self.passwordTextField.layer.cornerRadius = 5;
    self.passwordTextField.layer.masksToBounds = YES;
    self.usernameTextField.layer.cornerRadius = 5;
    self.usernameTextField.layer.masksToBounds = YES;
    
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    
    
    self.rememberMeSwitch.on = _authenticationManager.rememberMe;
    if (_authenticationManager.rememberMe) {
        self.usernameTextField.text = _authenticationManager.userName;
    } else {
#if DEBUG
        self.usernameTextField.text = @"jivetesting@gmail.com";
        self.passwordTextField.text = @"testing12";
#endif
        [self.usernameTextField becomeFirstResponder];
    }
    
    [Flurry logEvent:@"Login View"];
}

//@peter This hadles when you touch anywhere else on the screen the key board is dismissed.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification Handlers -


-(void)userMinimumDataLoaded:(NSNotification *)notification
{
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    if (_authenticationManager.pbx.v5.boolValue) {
        [client getVoicemails:nil];
    }
    [client RetrieveContacts:nil];
    
    if (!_authenticationManager.userLoadedMininumData) {
        if (self.errorOccurred) {
            [self errorInitializingApp:self.errorOccurred
                              useError:NO
                                 title:NSLocalizedString(@"Error", nil)
                               message:NSLocalizedString(@"An Unknown Error has Occurred, please try again", nil)];
        }
        else {
            [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil)
                            detail:NSLocalizedString(@"Preparing for first use", nil)];
        }
    }
    else
    {
        if (!loginCanceled) {
            [self hideHud];
            [self invalidateLoginTimer];
        }
    }
}


#pragma mark - Delegate Handlers -

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
        return NO;
    }
    else {
        [self validateFields];
        [self.passwordTextField resignFirstResponder];
        return YES;
    }
}

//- (UIImage *) screenshot {
//    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
//    
//    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
//    
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return image;
//}

- (void)validateFields
{
    if([self.usernameTextField.text length] != 0 && [self.passwordTextField.text length] != 0)
    {
        /*UIImage *coverImage = [self screenshot];
        coverImage = [coverImage applyBlurWithRadius:15.0 tintColor:[[UIColor darkGrayColor] colorWithAlphaComponent:.3] saturationDeltaFactor:.88 maskImage:nil];
        [self.coverImageView setAlpha:0.0];
        self.coverImageView.image = coverImage;
        JCAppIntro* appIntroSingleton = [JCAppIntro sharedInstance];
        appIntroSingleton.backgroundImageView = [[UIImageView alloc] initWithImage:coverImage];
        
        [UIView animateWithDuration:1.0 animations:^{
            [self.coverImageView setAlpha:1.0];
        } completion: ^(BOOL finished){
            if(finished) {
            }*/
        
        //}];
        
        [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil)
                        detail:NSLocalizedString(@"Logging In", nil)];
        
        [[JCOmniPresence sharedInstance] truncateAllTablesAtLogout];
        
        
        
        [_authenticationManager loginWithUsername:self.usernameTextField.text
                                         password:self.passwordTextField.text
                                        completed:^(BOOL success, NSError *error) {
                                            if (success) {
                                                [self authenticated:nil];
                                            }
                                            else {
                                                [self alertStatus:NSLocalizedString(@"Authentication Error", nil)
                                                          message:error.userInfo[@"error"] ? NSLocalizedString(error.userInfo[@"error"], nil) : error.localizedDescription];
                                                [self hideHud];
                                            }
                                        }];
		
		dispatch_async(dispatch_get_main_queue(), ^{
            self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:80
                                                          target:self
                                                        selector:@selector(loginIsTakingTooLong)
                                                        userInfo:nil
                                                         repeats:NO];
            
            [[NSRunLoop currentRunLoop] addTimer:self.loginTimer forMode:NSDefaultRunLoopMode];
        });
    }
    else
    {
        [self alertStatus:NSLocalizedString(@"Invalid Parameters", nil)
                  message:NSLocalizedString(@"UserName/Password Cannot Be Empty", nil)];
    }
}

#pragma mark - Private -

- (void) loginIsTakingTooLong
{
	[self errorInitializingApp:nil
                      useError:NO
                         title:NSLocalizedString(@"Login Timed Out", nil)
                       message:NSLocalizedString(@"This is taking longer than expected. Please check your connection and try again", nil)];
}

- (void) invalidateLoginTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loginTimer) {
            [self.loginTimer invalidate];
            self.loginTimer = nil;
        }
    });
}

-(void)alertStatus:(NSString*)title message:(NSString*)message
{
    NSLog(@"%@: %@", title, message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)refreshAuthenticationCredentialsFailed:(NSNotification*)notification
{
    [self hideHud];
    
    [self alertStatus:NSLocalizedString(@"Login Timeout", nil)
              message:NSLocalizedString(@"Login could not be completed at this time. Please try again later.", nil)];
}

- (void)authenticated:(NSNotification*)notification
{
    [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil)
                    detail:NSLocalizedString(@"Loading data", nil)];
    
    [self fetchMyLine];
}

NSString *const kJCLoginViewControllerProvisioningRequestString = @"<login \n user=\"%@\" \n password=\"%@\" \n man=\"Apple\" \n device=\"%@\" \n os=\"%@\" \n loc=\"%@\" \n lang=\"%@\" \n uuid=\"%@\" \n spid=\"cpc\" \n build=\"%@\" \n type=\"%@\" />";

#pragma mark - Fetch initial data



//voicemail
-(void)fetchMyLine{
    NSString * jiveId = [[NSUserDefaults standardUserDefaults] objectForKey:kUserName];
    [[JCV5ApiClient sharedClient] getMailboxReferencesForUser:jiveId completed:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if(suceeded){
			NSArray *pbxs = [PBX MR_findAll];
			if (pbxs.count == 0) {
				[self errorInitializingApp:error
                                  useError:NO
                                     title:NSLocalizedString(@"No PBX", nil)
                                   message:NSLocalizedString(@"This username is not associated with any PBX. Please contact your Administrator", nil)];
			}
			else if (pbxs.count > 1) {
				[self errorInitializingApp:error
                                  useError:NO
                                     title:NSLocalizedString(@"Multiple PBXs", nil)
                                   message:NSLocalizedString(@"This app does not support account with multiple PBXs at this time", nil)];
            }
			else {
				[self fetchProvisioningConfig];
			}
        }
		else {
            self.errorOccurred = error;
			[self errorInitializingApp:error
                              useError:NO
                                 title:NSLocalizedString(@"Server Unavailable", nil)
                               message:NSLocalizedString(@"We could not reach the server at this time. Please check your connection", nil)];
		}
    }];
}

//provisioning
- (void)fetchProvisioningConfig
{
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *model = [UIDevice currentDevice].model;
    NSString *os = [UIDevice currentDevice].systemVersion;
    NSString *uuid = [UIDevice currentDevice].identifierForVendor.UUIDString;
    NSString *type = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"ios.jive.phone" : @"ios.jive.tablet";
    
    NSString *xml = [NSString stringWithFormat:kJCLoginViewControllerProvisioningRequestString,
                     self.usernameTextField.text,
                     self.passwordTextField.text,
                     model,
                     os,
                     locale,
                     language,
                     uuid,
                     appBuildString,
                     type
                     ];
    
    [[JCV4ProvisioningClient sharedClient] requestProvisioningFile:xml completed:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if(suceeded){
            _authenticationManager.userLoadedMininumData = TRUE;
            
            
            
        }
        else {
            [self errorInitializingApp:error useError:YES title:nil message:nil];
        }
        
    }];
}

//- (void)fetchPBXInformation
//{
//    NSArray *mailboxes = [Lines MR_findAll];
//    
//    for (Lines *box in mailboxes) {
//		
//		PBX *pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:box.pbxId];
//		
//        [[JCV5ApiClient sharedClient] getPbxInformationFromUrl:pbx.selfUrl completed:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
//            //[self fetchMyContact];
//        }];
//    }
//}



// modified 06/20 - only loading my info (to be changed to new pbx servive) and voicemail. From fetching myEntitite, it will fetch voicemail and go into the application
//- (void)fetchMyEntity
//{
//    [self.client RetrieveMyEntitity:^(id JSON, id operation) {
//        [self fetchVoicemails];
//    } failure:^(NSError *err, id operation) {
//        [self errorInitializingApp:err];
//    }];
//}

//- (void)fetchEntities
//{
//    [self.client RetrieveClientEntitites:^(id JSON) {
//        [self fetchCompany];
//    } failure:^(NSError *err) {
//        [self errorInitializingApp:err];
//    }];
//}

//- (void)fetchCompany
//{
//    NSString* company = [[JCOmniPresence sharedInstance] me].resourceGroupName;
//    [self.client RetrieveMyCompany:company:^(id JSON) {
//        
//        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
//        Company *company = [Company MR_createInContext:localContext];
//        company.lastModified = JSON[@"lastModified"];
//        company.pbxId = JSON[@"pbxId"];
//        company.timezone = JSON[@"timezone"];
//        company.name = JSON[@"name"];
//        company.urn = JSON[@"urn"];
//        company.companyId = JSON[@"id"];
//        
//        //[[JCOmniPresence sharedInstance] me].entityCompany = company;
//        NSArray *clientEntities = [PersonEntities MR_findAll];
//        for (PersonEntities *entity in clientEntities) {
//            entity.entityCompany = company;
//        }
//        
//        [localContext MR_saveToPersistentStoreAndWait];
//        
////        [[JCAuthenticationManager sharedInstance] setUserLoadedMinimumData:YES];
//        
//        if (fastConnection) {
//            [self fetchPresence];
//        }
//        else {
//            [self hideHud];
//            if (self.doneLoadingContent && self.userIsDoneWithTutorial) {
//                [self goToApplication];
//            }
//         }
//        
//    } failure:^(NSError *err) {
//        NSLog(@"fetchCompany error: %@", err);
//        [self errorInitializingApp:err];
//    }];
//}

//- (void)fetchPresence
//{
//    [self.client RetrieveEntitiesPresence:^(BOOL updated) {
//        [self fetchConversations];
//    } failure:^(NSError *err) {
//        [self errorInitializingApp:err];
//    }];
//}
//
//- (void)fetchConversations
//{
//    [self.client RetrieveConversations:^(id JSON) {
//        [self fetchVoicemails];
//    } failure:^(NSError *err) {
//        [self errorInitializingApp:err];
//    }];
//}

#pragma mark - ShowHide logic

- (void)keyboardDidShow:(NSNotification *)notification
{
    //This animates the view when the keyboard appears and shifts it up in response.
//    [UIView animateKeyframesWithDuration:0.2 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
//        CGRect frame = self.loginViewContainer.frame;
//        CGRect usernameTextField = self.usernameTextField.frame;
//        
//        frame.origin.y = (frame.origin.y - kShiftKeyboardTHisMuch);
//        
//        usernameTextField.origin.y = (usernameTextField.origin.y - kShiftKeyboardTHisMuch);
//        
//        self.loginViewContainer.frame = frame;
//        self.usernameTextField.frame = usernameTextField;
//    } completion:^(BOOL finished) {
//        
//    }];
    
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    //This animates the view when the keyboard disappears and shifts it down in responce.
//    [UIView animateKeyframesWithDuration:0.2 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
//        CGRect frame = self.loginViewContainer.frame;
//        CGRect usernameTextField = self.usernameTextField.frame;
//        
//        frame.origin.y = (frame.origin.y + kShiftKeyboardTHisMuch);
//        usernameTextField.origin.y = (usernameTextField.origin.y + kShiftKeyboardTHisMuch);
//        self.loginViewContainer.frame = frame;
//        self.usernameTextField.frame = usernameTextField;
//    } completion:^(BOOL finished) {
//        
//    }];
}

- (void)errorInitializingApp:(NSError*)err useError:(BOOL)useError title:(NSString *)title message:(NSString *)message
{
    NSLog(@"errorInitializingApp: %@",err);
	loginCanceled = YES;
	[self invalidateLoginTimer];
    [self hideHud];
	
	if (useError) {
		[self alertStatus:NSLocalizedString(@"An error has occurred", nil)
                  message:err.localizedDescription];
	}
	else {
		[self alertStatus:title message:message];
	}
	
    [[JCAuthenticationManager sharedInstance] logout];
	
}

#pragma mark - Line selection update
- (void)didChangeLine:(Lines *)selectedLine
{
	[self checkIfLoadingHasFinished];
}

#pragma -mark HUD Operations
- (void)showHudWithTitle:(NSString*)title detail:(NSString*)detail
{
    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
    }
    
    hud.labelText = title;
    hud.detailsLabelText = detail;
    [hud show:YES];
}

- (void)hideHud
{
    if (hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [hud removeFromSuperview];
        hud = nil;
    }
}

- (IBAction)rememberMe:(id)sender {
    [[JCAuthenticationManager sharedInstance] setRememberMe:((UISwitch *)sender).on];
}

@end
