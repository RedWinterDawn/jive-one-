//
//  JCCoreDataTestDataFactory.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCoreDataTestDataFactory.h"

#import "NSDictionary+Validations.h"

// Models
#import "User.h"
#import "PBX.h"
#import "Line.h"
#import "LineConfiguration.h"
#import "DID.h"
#import "Contact.h"

NSString *const kJCCoreDataTestDataFactoryDataFile = @"TestCoreDataContents.plist";

@implementation JCCoreDataTestDataFactory

+ (void)loadTestCoreDataTestDataOnContext:(NSManagedObjectContext *)context
{
    NSArray *pathParts = [kJCCoreDataTestDataFactoryDataFile componentsSeparatedByString:@"."];
    NSString *filePath = [[NSBundle bundleForClass:[self class]]
                          pathForResource:[pathParts objectAtIndex:0]
                          ofType:[pathParts objectAtIndex:1]];
    
    NSArray *usersData = [[NSArray alloc] initWithContentsOfFile:filePath];
    NSAssert(usersData != nil, @"Should not be null");
    NSAssert(usersData.count > 1, @"Should have at least one user in the list");
    
    for (NSDictionary *userData in usersData) {
        User *user = [User MR_createInContext:context];
        user.jiveUserId = [userData stringValueForKey:@"jiveId"];
        NSArray *pbxsData = [userData arrayForKey:@"pbxs"];
        for (NSDictionary *pbxData in pbxsData) {
            [self processPbxData:pbxData forUser:user];
        }
    }
    
    // "Save" the test data, so it had "permanent IDs" like in real core data results.
    [context MR_saveOnlySelfAndWait];
}

+ (void)processPbxData:(NSDictionary *)pbxData forUser:(User *)user
{
    PBX *pbx = [PBX MR_createInContext:user.managedObjectContext];
    pbx.user = user;
    
    pbx.name = [pbxData stringValueForKey:@"name"];
    pbx.jrn  = [pbxData stringValueForKey:@"jrn"];
    pbx.v5   = [pbxData boolValueForKey:@"v5"];
    
    
    
    
    
    NSArray *linesData = [pbxData arrayForKey:@"lines"];
    for (NSDictionary *lineData in linesData) {
        [self processLineData:lineData forPbx:pbx];
    }
    
    NSArray *contactsData = [pbxData arrayForKey:@"contacts"];
    for (NSDictionary *contactData in contactsData) {
        [self processContactData:contactData forPbx:pbx];
    }
    
    NSArray *didsData = [pbxData arrayForKey:@"dids"];
    for (NSDictionary *didData in didsData) {
        [self processDidData:didData forPbx:pbx];
    }
}

+ (void)processLineData:(NSDictionary *)lineData forPbx:(PBX *)pbx
{
    Line *line = [Line MR_createInContext:pbx.managedObjectContext];
    line.pbx = pbx;
    line.pbxId = pbx.pbxId;
    
    line.name       = [lineData stringValueForKey:@"name"];
    line.jrn        = [lineData stringValueForKey:@"jrn"];
    line.extension  = [lineData stringValueForKey:@"extension"];
    line.active     = [lineData boolValueForKey:@"active"];
    line.mailboxJrn = [lineData stringValueForKey:@"mailboxJrn"];
    line.mailboxUrl = [lineData stringValueForKey:@"mailboxUrl"];
    
    NSDictionary *lineConfigurationData = [lineData dictionaryForKey:@"lineConfiguration"];
    LineConfiguration *lineConfiguration = [LineConfiguration MR_createInContext:line.managedObjectContext];
    lineConfiguration.line = line;
    
    lineConfiguration.display           = [lineConfigurationData stringValueForKey:@"display"];
    lineConfiguration.outboundProxy     = [lineConfigurationData stringValueForKey:@"outboundProxy"];
    lineConfiguration.registrationHost  = [lineConfigurationData stringValueForKey:@"registrationHost"];
    lineConfiguration.sipPassword       = [lineConfigurationData stringValueForKey:@"sipPassword"];
    lineConfiguration.sipUsername       = [lineConfigurationData stringValueForKey:@"sipUsername"];
}

+ (void)processContactData:(NSDictionary *)contactData forPbx:(PBX *)pbx
{
    Contact *contact = [Contact MR_createInContext:pbx.managedObjectContext];
    contact.pbx = pbx;
    contact.pbxId = pbx.pbxId;
    
    contact.name       = [contactData stringValueForKey:@"name"];
    contact.jrn        = [contactData stringValueForKey:@"jrn"];
    contact.extension  = [contactData stringValueForKey:@"extension"];
    contact.favorite   = [contactData boolValueForKey:@"favorite"];
    contact.jiveUserId = [contactData stringValueForKey:@"jiveUserId"];
}

+ (void)processDidData:(NSDictionary *)didData forPbx:(PBX *)pbx
{
    DID *did = [DID MR_createInContext:pbx.managedObjectContext];
    did.pbx = pbx;
    
    did.jrn = [didData stringValueForKey:@"jrn"];
    did.number = [didData stringValueForKey:@"number"];
    did.makeCall = [didData boolValueForKey:@"makeCall"];
    did.receiveCall = [didData boolValueForKey:@"receiveCall"];
    did.sendSMS = [didData boolValueForKey:@"sendSMS"];
    did.receiveSMS = [didData boolValueForKey:@"receiveSMS"];
    did.userDefault = [didData boolValueForKey:@"userDefault"];
}

@end
