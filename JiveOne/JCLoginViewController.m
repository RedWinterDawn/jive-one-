//
//  JCLoginViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLoginViewController.h"
#import "JCAuthenticationManager.h"
#import "JCAppDelegate.h"
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
    BOOL fastConnection;
	BOOL loginCanceled;
    MBProgressHUD *hud;
	NSTimer *loginTimer;
	
}

@property (nonatomic, strong) NSError *errorOccurred;

@end

@implementation JCLoginViewController

- (id)init {
    if (self = [super init]) {
    }
    return self;
}


//- (void)setClient:(JCRESTClient *)client
//{
//    _client = client;
//}
//@peter This hadles when you touch anywhere else on the screen the key board is dismissed.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.passwordTextField fixSecureTextFieldFont];
    //[self setClient:[JCRESTClient sharedClient]];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"]) {
        self.userIsDoneWithTutorial = YES;
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkIfLoadingHasFinished:) name:@"AppTutorialDismissed" object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAuthenticationCredentials:) name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAuthenticationCredentials:) name:kAuthenticationFromTokenFailedWithTimeout object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenValidityPassed:) name:kAuthenticationFromTokenSucceeded object:nil];
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    
    NSString* fontName = @"Avenir-Book";
    NSString* boldFontName = @"Avenir-Black";
    
    self.usernameTextField.placeholder =  NSLocalizedString(@"Email Address", nil);
    self.usernameTextField.font = [UIFont fontWithName:fontName size:16.0f];
    self.usernameTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.usernameTextField.layer.borderWidth = 1.0f;
    
    UIView* leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.usernameTextField.leftView = leftView;
    
    self.passwordTextField.placeholder =  NSLocalizedString(@"Password", nil);
    self.passwordTextField.font = [UIFont fontWithName:fontName size:16.0f];
    self.passwordTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.passwordTextField.layer.borderWidth = 1.0f;
    
#if DEBUG
    self.usernameTextField.text = @"jivetesting@gmail.com";
    self.passwordTextField.text = @"testing12";
    [self.passwordTextField becomeFirstResponder];
#endif
    
    // @Pete Adding rounded corners for the elements on login screen
    self.passwordTextField.layer.cornerRadius = 5;
    self.passwordTextField.layer.masksToBounds = YES;
    self.usernameTextField.layer.cornerRadius = 5;
    self.usernameTextField.layer.masksToBounds = YES;
    self.loginViewContainer.layer.cornerRadius = 5;
    [self.loginViewContainer.layer setCornerRadius:5];
    
    
    
    UIView* leftView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextField.leftView = leftView2;
    
    _loginStatusLabel.font = [UIFont fontWithName:boldFontName size:16.0f];
    // Do any additional setup after loading the view.
    fastConnection = [Common IsConnectionFast];
//    self.moreiconimageview.image= [JCStyleKit imageOfMoreIconLoginWithFrame:CGRectMake(0, 0, self.moreiconimageview.frame.size.width, self.moreiconimageview.frame.size.height)];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailedWithTimeout object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenSucceeded object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenSucceeded object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated{
//    if (self.view.frame.size.height <= 560){
//        
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
//    }
    
    
    if ([[JCAuthenticationManager sharedInstance] getRememberMe]) {
        NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:kUserName];
        self.usernameTextField.text = username;
        self.rememberMeSwitch.on = YES;
    }
    
    [Flurry logEvent:@"Login View"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

- (UIImage *) screenshot {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)validateFields
{
	loginCanceled = NO;
    self.loginStatusLabel.text = @"";
    if([self.usernameTextField.text length] != 0 && [self.passwordTextField.text length] != 0)
    {
        UIImage *coverImage = [self screenshot];
        coverImage = [coverImage applyBlurWithRadius:15.0 tintColor:[[UIColor darkGrayColor] colorWithAlphaComponent:.3] saturationDeltaFactor:.88 maskImage:nil];
        [self.coverImageView setAlpha:0.0];
        self.coverImageView.image = coverImage;
        JCAppIntro* appIntroSingleton = [JCAppIntro sharedInstance];
        appIntroSingleton.backgroundImageView = [[UIImageView alloc] initWithImage:coverImage];
        
        [UIView animateWithDuration:1.0 animations:^{
            [self.coverImageView setAlpha:1.0];
        } completion: ^(BOOL finished){
            if(finished) {
            }
            [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil) detail:NSLocalizedString(@"Logging In", nil)];
        }];
        
        [[JCAuthenticationManager sharedInstance] loginWithUsername:self.usernameTextField.text password:self.passwordTextField.text completed:^(BOOL success, NSError *error) {
            self.doneLoadingContent = NO;
            if (success) {
                [self tokenValidityPassed:nil];
            }
            else {
                if (error.userInfo[@"error"]) {
                    [self alertStatus:NSLocalizedString(@"Authentication Error", nil) message:error.userInfo[@"error"]];
                    NSLog(@"Authentication error: %@", error);
                    [self hideHud];
                    [UIView animateWithDuration:0.50 animations:^{
                        [self.coverImageView setAlpha:0.0];
                    } completion: ^(BOOL finished){
                    }];
                }
                else {
                    [self alertStatus:NSLocalizedString(@"Authentication Error", nil) message:error.localizedDescription];
                    NSLog(@"Authentication error: %@", error);
                    [self hideHud];
                    [UIView animateWithDuration:0.50 animations:^{
                        [self.coverImageView setAlpha:0.0];
                    } completion: ^(BOOL finished){
                    }];
                }
            }

        }];
		
		// start timer
		loginTimer = [NSTimer scheduledTimerWithTimeInterval:120
													  target:self
													selector:@selector(loginIsTakingTooLong)
													userInfo:nil
													 repeats:NO];
		
		[[NSRunLoop currentRunLoop] addTimer:loginTimer forMode:NSDefaultRunLoopMode];

		
    }
    else
    {
        [self alertStatus:NSLocalizedString(@"Invalid Parameters", nil) message: NSLocalizedString(@"UserName/Password Cannot Be Empty", nil)];
    }
}

- (void) loginIsTakingTooLong
{
	[self errorInitializingApp:nil useError:NO title:NSLocalizedString(@"Login Timed Out", nil) message:NSLocalizedString(@"This is taking longer than expected. Please check your connection and try again", nil)];
}

- (void) invalidateLoginTimer
{
	if (loginTimer) {
		[loginTimer invalidate];
	}
}

-(void)alertStatus:(NSString*)title message:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    
    [alert show];
}

- (void)refreshAuthenticationCredentials:(NSNotification*)notification
{
    [self hideHud];
    
    if (notification.object != nil && [kAuthenticationFromTokenFailedWithTimeout isEqualToString:(NSString *)notification.object]) {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Timeout", nil) message:NSLocalizedString(@"Login could not be completed at this time. Please try again later.", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertview show];
    }
    else {
    
        _loginStatusLabel.text = NSLocalizedString(@"Invalid username/password", @"Invalid username/password");
        _loginStatusLabel.hidden = NO;
    }
}

-(BOOL)seenTutorial
{
    return _seenTutorial = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"];
}

-(BOOL)doneLoadingContent
{
    if (!_doneLoadingContent) {
        _doneLoadingContent = NO;
    }
    return _doneLoadingContent;
}
-(BOOL)userIsDoneWithTutorial
{
    if (!_userIsDoneWithTutorial) {
        _userIsDoneWithTutorial = YES;
    }
    return _userIsDoneWithTutorial;
}

- (void)checkIfLoadingHasFinished:(NSNotification *)notification
{
	_userIsDoneWithTutorial = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"];
	if (notification && [[notification name] isEqualToString:@"AppTutorialDismissed"]) {
		_userIsDoneWithTutorial = YES;
		[[NSUserDefaults standardUserDefaults] setBool:self.userIsDoneWithTutorial forKey:@"seenAppTutorial"];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AppTutorialDismissed" object:nil];
	}
	
        NSLog (@"Successfully received the AppTutorialDismissed notification!");
        if (!self.doneLoadingContent) {
			if (self.errorOccurred) {
				[self errorInitializingApp:self.errorOccurred useError:NO title:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"An Unknown Error has Occurred, please try again", nil)];
			}
			else {
	            [self showHudWithTitle:@"One Moment Please" detail:@"Preparing for first use"];
			}
        }
        else if (_userIsDoneWithTutorial)
        {
			[self goToApplication];
			
// Re-add this when user can select line again
//			Lines *line = [Lines MR_findFirstByAttribute:@"inUse" withValue:[NSNumber numberWithBool:YES]];
//			if (line) {
//			}
//			else {
//				[self performSegueWithIdentifier:@"SelectLineLoginSegue" sender:self];
//			}
        }    
}

- (void)tokenValidityPassed:(NSNotification*)notification
{
	[self fetchMyMailboxes];
    if (!self.seenTutorial) {
        [Flurry logEvent:@"First Login"];
        [self hideHud];
//		JCAppIntro *introVC = [self.storyboard instantiateViewControllerWithIdentifier:@"JCAppIntro"];
//		[self presentViewController:introVC animated:YES completion:^{
//			//present
//		}];
        [self performSegueWithIdentifier: @"AppTutorialSegue" sender:self];
    }
    else
    {
        [self showHudWithTitle:@"One Moment Please" detail:@"Loading data"];
    }
}

#pragma mark - Fetch initial data
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
	
//	NSDictionary *userInformation = @{@"user": self.usernameTextField.text,
//									  @"password" : self.passwordTextField.text,
//									  @"man" : @"Apple",
//									  @"device" : [UIDevice currentDevice].model,
//									  @"os" : [UIDevice currentDevice].systemVersion,
//									  @"loc" : locale,
//									  @"lan" : language,
//									  @"uuid" : [UIDevice currentDevice].identifierForVendor.UUIDString,
//									  @"spid" : @"cpc",
//									  @"build" : appBuildString,
//									  @"type" :	[UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"ios.jive.phone" : @"ios.jive.tablet"};
//	NSString *test = [userInformation XMLString];

	

	
	
	//TODO: capture information to create the following structure
	
		
	NSString *xml = [NSString stringWithFormat:@"<login \n user=\"%@\" \n password=\"%@\" \n man=\"Apple\" \n device=\"%@\" \n os=\"%@\" \n loc=\"%@\" \n lang=\"%@\" \n uuid=\"%@\" \n spid=\"cpc\" \n build=\"%@\" \n type=\"%@\" />",
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
			//TODO: talk about logic. We should not prevent the user to get into the app if this fails. They
			// should still be able to access the rest of the app (directory, VM, etc) and be given a change to
			// fetch the provisioning file again...but then...do we store user creentials?
			self.doneLoadingContent = YES;
			[[JCAuthenticationManager sharedInstance] setUserLoadedMinimumData:YES];
			[self checkIfLoadingHasFinished:nil];
			//[self goToApplication];
			[self fetchVoicemailsMetadata];
			[self fetchContacts];
			
		}
		else {
			[self errorInitializingApp:error useError:YES title:nil message:nil];
		}
			
	}];
}


//voicemail
-(void)fetchMyMailboxes{
    NSString * jiveId = [[NSUserDefaults standardUserDefaults] objectForKey:kUserName];
    [[JCV5ApiClient sharedClient] getMailboxReferencesForUser:jiveId completed:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if(suceeded){
			NSArray *pbxs = [PBX MR_findAll];
			if (pbxs.count == 0) {
				[self errorInitializingApp:error useError:NO title:NSLocalizedString(@"No PBX", nil)	message:NSLocalizedString(@"This username is not associated with any PBX. Please contact your Administrator", nil)];
			}
			else if (pbxs.count > 1) {
				[self errorInitializingApp:error useError:NO title:NSLocalizedString(@"Multiple PBXs", nil)	message:NSLocalizedString(@"This app does not support account with multiple PBXs at this time", nil)];			}
			else {
				[self fetchProvisioningConfig];
			}
        }
		else {
            self.errorOccurred = error;
			[self errorInitializingApp:error useError:NO title:NSLocalizedString(@"Server Unavailable", nil) message:NSLocalizedString(@"We could not reach the server at this time. Please check your connection", nil)];
		}
    }];
}

- (void)fetchVoicemailsMetadata
{
//    NSPredicate *linesWithUrlNotNil = [NSPredicate predicateWithFormat:@"mailboxUrl != nil"];
//    NSArray* lines = [Lines MR_findAllWithPredicate:linesWithUrlNotNil];
	
//	NSTimer *timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(fetchMyContact) userInfo:nil repeats:NO];
//	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	
//	__block int count = 0;
	
	[[JCV5ApiClient sharedClient] getVoicemails:nil];

//    [[JCV5ApiClient sharedClient] getVoicemails:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
//
//		
//        if(suceeded) {
//            [[JCAuthenticationManager sharedInstance] setUserLoadedMinimumData:YES];
//        }
//		
//		if (count == lines.count) {
//			[timer invalidate];
//			[self fetchMyContact];
//		}
//		
//		NSLog(@"Count is now: %i, Line count is %lu", count, (unsigned long)lines.count);
//		
//    }];
	
	
}


//Contacts
- (void)fetchMyContact
{
		[[JCV5ApiClient sharedClient] RetrieveMyInformation:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
			[self fetchContacts];
		}];
	
}

- (void)fetchContacts
{
	[[JCV5ApiClient sharedClient] RetrieveContacts:nil];
	
//	if (!alreadyMakingContactsRequest) {
//		alreadyMakingContactsRequest = YES;
//		[[JCV5ApiClient sharedClient] RetrieveContacts:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
//			if (suceeded) {
//				_doneLoadingContent = YES;
//				[self hideHud];
//				if (self.userIsDoneWithTutorial) {
//					[self goToApplication];
//				}
//			}
//		}];
//	}
	
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

- (void)goToApplication
{
	if (!loginCanceled) {
		[self hideHud];
		[self invalidateLoginTimer];
		JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
		[delegate changeRootViewController:JCRootTabbarViewController];
	}
}



- (void)errorInitializingApp:(NSError*)err useError:(BOOL)useError title:(NSString *)title message:(NSString *)message
{
    NSLog(@"errorInitializingApp: %@",err);
	loginCanceled = YES;
	[self invalidateLoginTimer];
    [self hideHud];
	
	if (useError) {
		[self alertStatus:NSLocalizedString(@"An error has occurred", nil) message:err.localizedDescription];
	}
	else {
		[self alertStatus:title message:message];
	}
	
    [[JCAuthenticationManager sharedInstance] logout:self];
	
}

#pragma mark - Line selection update
- (void)didChangeLine:(Lines *)selectedLine
{
	[self checkIfLoadingHasFinished:nil];
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
//    self.doneLoadingContent = YES;
    if (hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [hud removeFromSuperview];
        hud = nil;
    }
}


- (IBAction)termsAndConditionsButton:(id)sender {
    [self performSegueWithIdentifier: @"TCSegue" sender: self];
}

- (IBAction)rememberMe:(id)sender {
    
    [[JCAuthenticationManager sharedInstance] setRememberMe:((UISwitch *)sender).on];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"SelectLineLoginSegue"]) {
		UIView *view = ((JCAppDelegate *)[UIApplication sharedApplication].delegate).window;
        UIImage *underlyingView = [Common imageFromView:view];
        underlyingView = [underlyingView applyBlurWithRadius:5 tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] saturationDeltaFactor:1.3 maskImage:nil];
		
		
		[segue.destinationViewController setBluredBackgroundImage:underlyingView];
		[segue.destinationViewController setDelegate:self];
		[segue.destinationViewController setHidesBottomBarWhenPushed:YES];
	}
}

@end
