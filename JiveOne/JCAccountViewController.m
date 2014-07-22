//
//  JCAccountViewController.m
//  JiveOne
//
//  Created by Daniel George on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAccountViewController.h"
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
#import "Lines+Custom.h"
//#import "JCStyleKit.h"

@interface JCAccountViewController () <MFMailComposeViewControllerDelegate>
{
    PersonEntities *me;
    NSMutableArray *presenceValues;
    BOOL isPickerDisplay;
}

@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) Lines *selectedLine;
@property (weak, nonatomic) IBOutlet UILabel *selectedLineLabel;
@property (nonatomic, strong) NSManagedObjectContext *managedContext;

@end

@implementation JCAccountViewController

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

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
	
	_managedContext = [NSManagedObjectContext MR_contextForCurrentThread];
    
    [self loadViews];
    if(![[NSUserDefaults standardUserDefaults] objectForKey:UDdeviceToken]){
        //Register for PushNotifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
    }
    
//    self.tableView.backgroundColor = [UIColor whiteColor];
//    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20);

}

- (void) loadViews
{
//    self.userNameDetail.text = me.firstLastName;
    NSString * jiveId = [[NSUserDefaults standardUserDefaults] objectForKey:kUserName];
    self.userNameDetail.text = jiveId;
	
	_selectedLine = [Lines MR_findFirstByAttribute:@"inUse" withValue:[NSNumber numberWithBool:YES] inContext:self.managedContext];
	if (_selectedLine) {
		self.selectedLineLabel.text = self.selectedLine.externsionNumber;
	}
	else {
		self.selectedLineLabel.text = @"No line selected";
	}
	

//    self.userMoodDetail.text = @"I'm not in the mood today";
//    self.userTitleDetail.text = @"Developer of Awesome";
//    self.userImage.image = [JCStyleKit imageOfCanvas15WithFrame:CGRectMake(77, 0, 166, self.userImage.frame.size.height)];
//    self.userImage.backgroundColor = [UIColor colorWithRed:.883 green:.883 blue:.883 alpha:1];
    


//    UIImage *backButton = [JCStyleKit imageOfBack_buttonWithFrame:CGRectMake(0, 0, self.eulaImageView.frame.size.width, self.eulaImageView.frame.size.height)];
//
//    UIImage *reverseButton = [UIImage imageWithCGImage:backButton.CGImage
//                                                  scale:backButton.scale    
//                                            orientation:UIImageOrientationUpMirrored];
//    self.eulaImageView.image = reverseButton;
//    [self.eulaImageView setTintColor:[UIColor orangeColor]];
//    self.feedbackImageView.image = reverseButton;
//    self.logoutImageView.image = [JCStyleKit imageOfLogoutWithFrame:CGRectMake(0, 0, self.logoutImageView.frame.size.width, self.logoutImageView.frame.size.height)];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"Account View"];
    if (!me) {
        me = [[JCOmniPresence sharedInstance] me];
    }
    
//    [self.presenceDetail setText:[self getPresence:me.entityPresence.interactions[@"chat"][@"code"]]];
    

}

- (void)updateAccountInformation
{
//    [[JCRESTClient sharedClient] RetrieveMyEntitity:^(id JSON, id operation) {
//        
//        NSDictionary *entity = (NSDictionary*)JSON;
//        
//        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
//        me.presence = entity[@"presence"];
//        me.email = entity[@"email"];
//        me.externalId = entity[@"externalId"];
//        me.resourceGroupName = entity[@"company"];
//        me.location = entity[@"location"];
//        me.firstLastName = entity[@"name"][@"firstLast"];
//        me.groups = entity[@"groups"];
//        me.urn = entity[@"urn"];
//        me.id = entity[@"id"];
//        me.picture = entity[@"picture"];
//
//        [localContext MR_saveToPersistentStoreAndWait];
//        
//        //TODO: using company id, query to get PBX?
//        [self retrieveCompany:[JSON objectForKey:@"company"]];
//        
//        [self loadViews];
//        
//    } failure:^(NSError *err, id operation) {
//        NSLog(@"%@", err);
//    }];
}

-(void) retrieveCompany:(NSString*)companyURL{
//    [[JCRESTClient sharedClient] RetrieveMyCompany:companyURL:^(id JSON) {
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
//        me.entityCompany = company;
//        
//        [localContext MR_saveToPersistentStoreAndWait];
//        
//        [self performSelectorOnMainThread:@selector(loadViews) withObject:nil waitUntilDone:YES];
//        
//    } failure:^(NSError *err) {
//        NSLog(@"%@", err);
//    }];
//    
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

#pragma makr - Line Selector Delegate
- (void)didChangeLine:(Lines *)selectedLine
{
	[self selectedLineChanged:selectedLine];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;//TODO: change to 4 when brining back presence.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
//    if (indexPath.section != 0) {
//        cell.contentView.layer.borderWidth = 1.0f;
//        cell.contentView.layer.borderColor = [UIColor lightGrayColor].CGColor;
//    }

    
    return cell;
}

//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    //UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 22)];
////    headerView.backgroundColor = [UIColor whiteColor];
//    
//    return headerView;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return 14;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(indexPath.section == 1 && indexPath.row == 2) {
        
        UIView *view = ((JCAppDelegate *)[UIApplication sharedApplication].delegate).window;
        UIImage *underlyingView = [Common imageFromView:view];
        underlyingView = [underlyingView applyBlurWithRadius:5 tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] saturationDeltaFactor:1.3 maskImage:nil];
        [self performSegueWithIdentifier:@"PresenceSegue" sender:underlyingView];
        
    }
//    else

        //Eula or leave feedback
        
        if([cell.reuseIdentifier isEqualToString:@"TermsOfService"])
        {
            [Flurry logEvent:@"TermsOfService button clicked"];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
            
            [self presentViewController:[storyboard instantiateViewControllerWithIdentifier:@"JCTermsAndConditonsVCViewControllerContainer"] animated:YES completion:nil];
        }
        else if ([cell.reuseIdentifier isEqualToString:@"LeaveFeedback"])
        {
            //send email to mobileapps+ios@jive.com
            [self leaveFeedbackPressed];
            
            
        }
        else if ([cell.reuseIdentifier isEqualToString:@"LogOut"])
        {
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
        [mailViewController setToRecipients:[NSArray arrayWithObject:kFeedbackEmail]];
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
- (void)selectedLineChanged:(Lines *)line
{
	line = [Lines MR_findFirstByAttribute:@"lineId" withValue:line.lineId inContext:self.managedContext];
	
	Lines *previousLine;
	if (_selectedLine) {
		previousLine = self.selectedLine;
	}
	_selectedLine = line;
	
	self.selectedLineLabel.text = self.selectedLine.externsionNumber;
	
	line.inUse = [NSNumber numberWithBool:YES];
	if (previousLine) {
		previousLine.inUse = [NSNumber numberWithBool:NO];
	}
	
	[self.managedContext MR_saveToPersistentStoreAndWait];

}


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
    
//    if (type != JCPresenceTypeNone) {
//        [[JCRESTClient sharedClient] UpdatePresence:type success:^(BOOL updated) {
//            NSLog(@"P%i", updated);
//            NSLog(@"Presence Updated");
//        } failure:^(NSError *err) {
//            NSLog(@"%@", err);
//            NSLog(@"Presence Update Error");
//        }];
//    }    
}

- (NSString *)getPresence:(NSNumber *)presence
{
    JCPresenceType type = (JCPresenceType) [presence integerValue];    
    self.presenceDetailView.presenceType = type;
    
    switch ([presence integerValue]) {
        case JCPresenceTypeAvailable:
            return kPresenceAvailable;
            break;
        case JCPresenceTypeBusy:
            return kPresenceBusy;
            break;
        case JCPresenceTypeDoNotDisturb:
            return kPresenceDoNotDisturb;
            break;
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
