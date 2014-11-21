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
#import "LineConfiguration+Custom.h"

//#import "JCStyleKit.h"

#import "JCCallCardManager.h"

@interface JCAccountViewController () <MFMailComposeViewControllerDelegate, NSFileManagerDelegate>
{
//    PersonEntities *me;
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
    
//    if (!me) {
//        me = [[JCOmniPresence sharedInstance] me];
//    }
	
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
    self.userUsername.text = jiveId;
    
    Lines *line = [Lines MR_findFirst];
    if (line) {
        self.userDisplayName.text = line.displayName;
        self.userExternsionNumber.text = [NSString stringWithFormat:@"Ext. %@", line.externsionNumber];
    }
    
    PBX *pbx = [PBX MR_findFirst];
    if (pbx) {        
        self.userPBX.text = [NSString stringWithFormat:@"%@ PBX on %@", pbx.name, [pbx.v5 boolValue] ? @"V5" : @"V4"];
    }
	
//	_selectedLine = [Lines MR_findFirstByAttribute:@"inUse" withValue:[NSNumber numberWithBool:YES] inContext:self.managedContext];
//	if (_selectedLine) {
//		self.selectedLineLabel.text = self.selectedLine.externsionNumber;
//        self.ext.text = self.selectedLine.externsionNumber;
//	}
//	else {
//		self.selectedLineLabel.text = @"No line selected";
//        self.ext.text = self.selectedLine.externsionNumber;
//	}
	

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
//    if (!me) {
//        me = [[JCOmniPresence sharedInstance] me];
//    }
    
//    [self.presenceDetail setText:[self getPresence:me.entityPresence.interactions[@"chat"][@"code"]]];
    

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

#pragma mark - Line Selector Delegate
- (void)didChangeLine:(Lines *)selectedLine
{
	[self selectedLineChanged:selectedLine];
}

#pragma mark - Table view data source

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

    //Eula or leave feedback
    if([cell.reuseIdentifier isEqualToString:@"TermsOfService"])
    {
        [Flurry logEvent:@"TermsOfService button clicked"];
        [self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"JCTermsAndConditonsVCViewControllerContainer"] animated:YES completion:nil];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"LeaveFeedback"])
        [self leaveFeedbackPressed];
    
    else if ([cell.reuseIdentifier isEqualToString:@"LogOut"])
        [self logoutButtonPress];
}


#pragma mark - Table Actions
- (void) logoutButtonPress{
    [[JCAuthenticationManager sharedInstance] logout:self];
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
