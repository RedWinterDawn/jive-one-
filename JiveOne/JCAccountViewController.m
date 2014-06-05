//
//  JCAccountViewController.m
//  JiveOne
//
//  Created by Daniel George on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAccountViewController.h"
#import "JCOsgiClient.h"
#import "JCAuthenticationManager.h"
#import "KeychainItemWrapper.h"
#import "PersonEntities.h"
#import "Company.h"
#import <AudioToolbox/AudioToolbox.h>
#import "JCTermsAndConditonsVCViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "JCPresenceViewController.h"
#import "Common.h"
#import "UIImage+ImageEffects.h"
#import "JCAppDelegate.h"

@interface JCAccountViewController () <MFMailComposeViewControllerDelegate>
{
    PersonEntities *me;
    NSMutableArray *presenceValues;
    BOOL isPickerDisplay;
}

@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation JCAccountViewController



- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (!me) {
        me = [[JCOmniPresence sharedInstance] me];
        
        if (!me.entityCompany) {
            [self retrieveCompany:me.resourceGroupName];
        }
    }
    
    [self loadViews];
    if(![[NSUserDefaults standardUserDefaults] objectForKey:UDdeviceToken]){
        //Register for PushNotifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
    }
}

- (void) loadViews
{
    self.userNameDetail.text = me.firstLastName;
    
    if (me.entityCompany) {
        self.jivePhoneNumber.text = me.entityCompany.name;
        self.jiveMessenger.text = me.email;
        self.jivePhoneNumber.text = me.externalId;
    }
    
    [self.presenceDetail setText:[self getPresence:me.entityPresence.interactions[@"chat"][@"code"]]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"More View"];
    if (!me) {
        me = [[JCOmniPresence sharedInstance] me];
    }
    
}

- (void)updateAccountInformation
{
    [[JCOsgiClient sharedClient] RetrieveMyEntitity:^(id JSON, id operation) {
        
        NSDictionary *entity = (NSDictionary*)JSON;
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        me.presence = entity[@"presence"];
        me.email = entity[@"email"];
        me.externalId = entity[@"externalId"];
        me.resourceGroupName = entity[@"company"];
        me.location = entity[@"location"];
        me.firstLastName = entity[@"name"][@"firstLast"];
        me.groups = entity[@"groups"];
        me.urn = entity[@"urn"];
        me.id = entity[@"id"];
        me.picture = entity[@"picture"];

        [localContext MR_saveToPersistentStoreAndWait];
        
        //TODO: using company id, query to get PBX?
        [self retrieveCompany:[JSON objectForKey:@"company"]];
        
        [self loadViews];
        
    } failure:^(NSError *err, id operation) {
        NSLog(@"%@", err);
    }];
}

-(void) retrieveCompany:(NSString*)companyURL{
    [[JCOsgiClient sharedClient] RetrieveMyCompany:companyURL:^(id JSON) {
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        Company *company = [Company MR_createInContext:localContext];
        company.lastModified = JSON[@"lastModified"];
        company.pbxId = JSON[@"pbxId"];
        company.timezone = JSON[@"timezone"];
        company.name = JSON[@"name"];
        company.urn = JSON[@"urn"];
        company.companyId = JSON[@"id"];
        
        me.entityCompany = company;
        
        [localContext MR_saveToPersistentStoreAndWait];
        
        [self performSelectorOnMainThread:@selector(loadViews) withObject:nil waitUntilDone:YES];
        
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - JCPresenceDelegate

- (void)didChangePresence:(JCPresenceType)presenceType
{
    [self presenceTypeChanged:presenceType];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(indexPath.section == 1){
        //launch action sheet
//        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
//                                kPresenceAvailable,
//                                kPresenceAway,
//                                kPresenceDoNotDisturb,
//                                kPresenceOffline,
//                                nil];
        //[popup showFromTabBar:self.tabBarController.tabBar];
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        
//        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
//                                                                 delegate:self
//                                                        cancelButtonTitle:@"Cancel"
//                                                   destructiveButtonTitle:nil
//                                                        otherButtonTitles:nil];
//        
//        _actionSheet = popup   ;
//        
//        UIView *test1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _actionSheet.frame.size.width, 44)];
//        test1.backgroundColor = [UIColor blackColor];
//        UIButton * testButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
//        [testButton1 addSubview:test1];
//        
//        [[[_actionSheet valueForKey:@"_buttons"] objectAtIndex:0] setTitle:@""];
//        [[[_actionSheet valueForKey:@"_buttons"] objectAtIndex:0] addSubview:testButton1];
//        [[[_actionSheet valueForKey:@"_buttons"] objectAtIndex:1] setImage:[UIImage imageNamed:@"email.png"] forState:UIControlStateNormal];
//        [[[_actionSheet valueForKey:@"_buttons"] objectAtIndex:2] setImage:[UIImage imageNamed:@"facebook_black.png"] forState:UIControlStateNormal];
//        //*********** Cancel
//        [[[_actionSheet valueForKey:@"_buttons"] objectAtIndex:3] setImage:[UIImage imageNamed:@"cancel.png"] forState:UIControlStateNormal];
        //[actionSheet showFromRect:button.frame inView:self.view animated:YES];
//        UIDatePicker *pickerView = [[UIDatePicker alloc] init];
//        pickerView.datePickerMode = UIDatePickerModeDateAndTime;
//        [pickerView addTarget:self action:@selector(scheduleCampaign:) forControlEvents:UIControlEventValueChanged];
//        
//        CGRect pickerRect = pickerView.bounds;
//        pickerRect.origin.y = 250;
//        pickerRect.size.width = 300;
//        pickerView.bounds = pickerRect;
//        [pickerView setBackgroundColor:[UIColor clearColor]];
//        
//        UIToolbar* blurBackgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, pickerView.bounds.size.width, pickerView.bounds.size.height)];
//        
//        [pickerView insertSubview:blurBackgroundToolbar atIndex:0];
        
        //[_actionSheet addSubview:pickerView];
//        [_actionSheet showFromTabBar:self.tabBarController.tabBar];
        
//        JCPresenceViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"JCPresenceSelectionViewController"];
//        [self presentViewController:vc animated:YES completion:^{
//            //dd
//        }];
        
        UIView *view = ((JCAppDelegate *)[UIApplication sharedApplication].delegate).window;
        UIImage *underlyingView = [Common imageFromView:view];
        underlyingView = [underlyingView applyBlurWithRadius:5 tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] saturationDeltaFactor:1.3 maskImage:nil];
        [self performSegueWithIdentifier:@"PresenceSegue" sender:underlyingView];
    }
    else if(indexPath.section == 2){
        //Eula or leave feedback
        if([cell.textLabel.text isEqualToString:@"EULA / Terms of Service"]){
            [Flurry logEvent:@"EULA button clicked"];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
            
            [self presentViewController:[storyboard instantiateViewControllerWithIdentifier:@"JCTermsAndConditonsVCViewControllerContainer"] animated:YES completion:nil];
            
        }
        else if ([cell.textLabel.text isEqualToString:@"Leave Feedback"]){
            //send email to mobileapps+ios@jive.com
            [self leaveFeedbackPressed];
            
            
        }
    }
    else if (indexPath.section == 3) {
        [self logoutButtonPress];
    }
}


#pragma mark - Table Actions
- (void) logoutButtonPress{
    [[JCAuthenticationManager sharedInstance] logout:self];
    [self.tabBarController performSegueWithIdentifier:@"logoutSegue" sender:self.tabBarController];
    [Flurry logEvent:@"Log out"];
}

#pragma mark - Mail Delegate
-(void) leaveFeedbackPressed{
    
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setToRecipients:[NSArray arrayWithObject:@"MobileApps+ios@jive.com"]];
        [mailViewController setSubject:@"Feedback"];
        
        //get device specs
        UIDevice *currentDevice = [UIDevice currentDevice];
        NSString *model = [currentDevice model];
        NSString *systemVersion = [currentDevice systemVersion];
        NSString *appVersion = [[NSBundle mainBundle]
                                objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        NSString *country = [[NSLocale currentLocale] localeIdentifier];
        
        NSString *bodyTemplate = [NSString stringWithFormat:@"<strong>Description of feedback:</strong> <br><br><br><br><br><hr><strong>Device Specs</strong><br>Model: %@ <br> System Version: %@ <br> App Version: %@ <br> Country: %@",
         model, systemVersion, appVersion, country];
        
        
        [mailViewController setMessageBody:bodyTemplate isHTML:YES];
        
        [self presentViewController:mailViewController animated:YES completion:nil];
        
    }
    
    else {
        
        NSLog(@"Device is unable to send email in its current state.");
        
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - UIActionSheet Delegate
- (void) presenceTypeChanged:(JCPresenceType)type
{
    NSString *state;
    
    if (type == JCPresenceTypeAvailable) {
        state = kPresenceAvailable;
    }
    else if (type == JCPresenceTypeBusy) {
        state = kPresenceBusy;
    }
    else if (type == JCPresenceTypeDoNotDisturb) {
        state = kPresenceDoNotDisturb;
    }
    else if (type == JCPresenceTypeOffline) {
        state = kPresenceOffline;
    }
    else {
        state = self.presenceDetail.text;
    }
    
    [self.presenceDetail setText:state];
    self.presenceDetailView.presenceType = type;
    
    if (type != JCPresenceTypeNone) {
        [[JCOsgiClient sharedClient] UpdatePresence:type success:^(BOOL updated) {
            NSLog(@"%i", updated);
        } failure:^(NSError *err) {
            NSLog(@"%@", err);
        }];
    }    
}

- (NSString *)getPresence:(NSNumber *)presence
{
    switch ([presence integerValue]) {
        case JCPresenceTypeAvailable:
            return kPresenceAvailable;
            break;
        case JCPresenceTypeAway:
            return kPresenceAway;
            break;
        case JCPresenceTypeBusy:
            return kPresenceBusy;
            break;
        case JCPresenceTypeDoNotDisturb:
            return kPresenceDoNotDisturb;
            break;
        case JCPresenceTypeInvisible:
            return kPresenceInvisible;
            break;
        case JCPresenceTypeOffline:
            return kPresenceOffline;
            break;
            
        default:
            return @"Unknown";
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [segue.destinationViewController setBluredBackgroundImage:sender];
    [segue.destinationViewController setDelegate:self];
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
}


@end
