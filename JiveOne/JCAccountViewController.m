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
#import "ClientEntities.h"
#import "Company.h"
#import <AudioToolbox/AudioToolbox.h>


@interface JCAccountViewController ()
{
    ClientEntities *me;
    NSMutableArray *presenceValues;
    BOOL isPickerDisplay;
}

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
}

- (void) loadViews
{
    self.userNameDetail.text = me.firstLastName;
    
    if (me.entityCompany) {
        self.jivePhoneNumber.text = me.entityCompany.name;
        self.jiveMessenger.text = me.externalId;
    }
    
    [self.presenceDetail setTitle:[self getPresence:me.entityPresence.interactions[@"chat"][@"code"]]  forState:UIControlStateNormal];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!me) {
        me = [[JCOmniPresence sharedInstance] me];
    }
    
}

- (void)updateAccountInformation
{
    [[JCOsgiClient sharedClient] RetrieveMyEntitity:^(id JSON) {
        
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
        
    } failure:^(NSError *err) {
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

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
// 
//}

#pragma mark - Actions from UI
- (IBAction)logoutButtonPress:(id)sender {
    
    [[JCAuthenticationManager sharedInstance] logout:self];
}

- (IBAction)presenceButtonSelected:(id)sender {
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Select Presence option:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                            kPresenceAvailable,
                            kPresenceAway,
                            kPresenceBusy,
                            kPresenceDoNotDisturb,
                            kPresenceInvisible,
                            kPresenceOffline,
                            nil];
    [popup showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *state;
    JCPresenceType type;
    
    switch (buttonIndex) {
        case 0:
            state = kPresenceAvailable;
            type = JCPresenceTypeAvailable;
            break;
        case 1:
            state = kPresenceAway;
            type = JCPresenceTypeAway;
            break;
        case 2:
            state = kPresenceBusy;
            type = JCPresenceTypeBusy;
            break;
        case 3:
            state = kPresenceDoNotDisturb;
            type = JCPresenceTypeDoNotDisturb;
            break;
        case 4:
            state = kPresenceInvisible;
            type = JCPresenceTypeInvisible;
            break;
        case 5:
            state = kPresenceOffline;
            type = JCPresenceTypeOffline;
            break;
        default:
            state = self.presenceDetail.titleLabel.text;
            type = JCPresenceTypeNone;
    }
    
    [self.presenceDetail setTitle:state forState:UIControlStateNormal];
    
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


@end
