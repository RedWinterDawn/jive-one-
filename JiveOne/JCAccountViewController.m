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
#import <PocketSVG/PocketSVG.h>

@interface JCAccountViewController () <MFMailComposeViewControllerDelegate>
{
    PersonEntities *me;
    NSMutableArray *presenceValues;
    BOOL isPickerDisplay;
}

@property (nonatomic, strong) UIActionSheet *actionSheet;

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
    
    [self loadViews];
    if(![[NSUserDefaults standardUserDefaults] objectForKey:UDdeviceToken]){
        //Register for PushNotifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
    }
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20);
}

- (void) loadViews
{
    self.userNameDetail.text = me.firstLastName;
    self.userMoodDetail.text = @"I'm not in the mood today";
    self.userTitleDetail.text = @"Developer of Awesome";
    self.userImage.image = [UIImage imageNamed:@"boss.jpg"];
    
    CGPathRef pathRef = [PocketSVG pathFromSVGFileNamed:@"logout"];
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = pathRef;
    
    layer.lineWidth = 1;
    layer.strokeColor = [[UIColor blackColor] CGColor];
    layer.fillColor = [[UIColor blackColor] CGColor];
    layer.fillRule = kCAFillRuleNonZero;
    
    //layer.mask.bounds = self.presenceAccessory.layer.mask.bounds;
    layer.bounds = self.presenceAccessory.layer.bounds;
    CGRect frame = CGRectMake(layer.frame.origin.x, layer.frame.origin.y, 25, 25);
    frame.size = CGSizeMake(25, 25);
    [layer setFrame:frame];
    //layer.frame = self.presenceAccessory.layer.frame;
    //layer.masksToBounds = YES;

    [self.presenceAccessory.layer addSublayer:layer];
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
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section != 0) {
        cell.contentView.layer.borderWidth = 1.0f;
        cell.contentView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }

    
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 22)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    return headerView;
}

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
    if(indexPath.section == 1){
        
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
            NSLog(@"P%i", updated);
            NSLog(@"Presence Updated");
        } failure:^(NSError *err) {
            NSLog(@"%@", err);
            NSLog(@"Presence Update Error");
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
