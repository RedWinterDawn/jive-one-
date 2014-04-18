//
//  JCDirectoryTests.m
//  JiveOne
//
//  Created by Daniel George on 3/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "JCDirectoryViewController.h"
#import "JCAuthenticationManager.h"
#import "PersonEntities.h"

@interface JCDirectoryTests : XCTestCase
@property (nonatomic, strong) JCDirectoryViewController *JCDVC;
@end

@implementation JCDirectoryTests

- (void)setUp
{
    [super setUp];
    
    // test.my.jive.com token for user jivetesting10@gmail.com
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    if ([self stringIsNilOrEmpty:token]) {
        if ([self stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *testToken = kTestAuthKey;
            NSDictionary *oauth_response = [NSDictionary dictionaryWithObjectsAndKeys:testToken, @"access_token", nil];
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:oauth_response];
        }
    }
    
    
    // instantiate self.JCDVC from Storyboard so we get the same instance the app is using
    self.JCDVC = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"JCDirectoryViewController"];
    [self.JCDVC viewDidLoad];
    
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

#pragma mark Integration Tests
- (void)testLoadLocalDirectory {
    
    if(!self.JCDVC.segControl){
        self.JCDVC.segControl = [[UISegmentedControl alloc] init];
    }
    [self.JCDVC.segControl setSelectedSegmentIndex:1];
    
    [self.JCDVC segmentChanged:nil];
    
    
    XCTAssertNotNil(self.JCDVC.clientEntitiesArray, @"Client Entities Array from local contacts did not get instantiated");
    XCTAssertTrue([self.JCDVC.clientEntitiesArray count] == 26, @"The array does not have 26 arrays");
    int counter=1;
    
    for (NSMutableArray *oneOfTwentySixArrays in self.JCDVC.clientEntitiesArray) {
        
        XCTAssertNotNil(oneOfTwentySixArrays, @"The [%d]th array is nil", counter );
        counter++;
        
        if (oneOfTwentySixArrays.count != 0) {
            NSMutableDictionary *localDictionary = oneOfTwentySixArrays[0];
            
            XCTAssertNotNil([localDictionary objectForKey:@"firstName"], @"Dictionary does not contain firstName string");
            XCTAssertNotNil([localDictionary objectForKey:@"lastName"], @"Dictionary does not contain lastName string");
        }
    }
}

- (void)testLoadCompanyDirectory {
    
    [self.JCDVC.segControl setSelectedSegmentIndex:0];
    
    [self.JCDVC segmentChanged:nil];
    
    XCTAssertNotNil(self.JCDVC.clientEntitiesArray, @"Client Entities Array from company contacts did not get instantiated");
    XCTAssertTrue([self.JCDVC.clientEntitiesArray count] == 26, @"The array does not have 26 arrays");
    int counter=1;
    for (NSMutableArray *oneOfTwentySixArrays in self.JCDVC.clientEntitiesArray) {
        
        XCTAssertNotNil(oneOfTwentySixArrays, @"The [%d]th array is nil", counter );
        counter++;
        
        if (oneOfTwentySixArrays.count != 0) {
            PersonEntities *testContact = oneOfTwentySixArrays[0];
            
            
            XCTAssertNotNil(testContact.firstName, @"Company contact does not contain firstName string");
            XCTAssertNotNil(testContact.lastName, @"Company contact not contain lastName string");
        }
    }
    
}

-(void) testSearchTermFiltersContact{
    //after viewDidLoad, company contacts will be loaded
    XCTAssertTrue(0==[self.JCDVC.clientEntitiesSearchArray count], @"clientEntitiesSearchArray should be empty");
    [self.JCDVC segmentChanged:nil];
    
    
    NSArray *clientEntities = [NSArray arrayWithArray:self.JCDVC.clientEntitiesArray];
    
//    if (clientEntities.count == 0) {
//        clientEntities = [ClientEntities MR_findAll];
//    }
    
    XCTAssertTrue(clientEntities.count > 0, @"Array should contain company contacts");
    
    //get second contact from list
    NSArray *contacts = self.JCDVC.clientEntitiesArray;
    int index = -1;
    for (int i = 0; i < contacts.count; i++) {
        
        NSArray *letter = contacts[i];
        if (letter.count > 0) {
            index = i;
            break;
        }
    }
    
    XCTAssertFalse(index == -1, @"No contacts found");
    
    PersonEntities *secondContact = contacts[index][0];
    
    //calcuate how many times that name exists in clientEntitiesArray, so that we know how many to expect in clientEntitiesSearchArray
    // This line had a warning that was causing the test to fail on certain devices. (int) casts result as proper type, passes test now
    int aSectionCount = (int)((NSArray*)self.JCDVC.clientEntitiesArray[0]).count;
    
    int nameCount = 0;
    for (int i =0; i< aSectionCount; i++) {
        if( [((PersonEntities*)self.JCDVC.clientEntitiesArray[0][i]).firstLastName isEqualToString:secondContact.firstLastName]){
            nameCount++;
        }
    }
    
    //filter clientEntitiesSearchArray by Name
    [self.JCDVC filterContentForSearchText:secondContact.firstLastName scope:nil];
    
    XCTAssertTrue(nameCount==[((NSArray*)self.JCDVC.clientEntitiesSearchArray[0]) count], @"clientEntitiesSearchArray should contain only nameCount contact(s)");
    
    //calcuate how many times that name exists in clientEntitiesArray, so that we know how many to expect in clientEntitiesSearchArray
    int emailCount = 0;
    for (int i =0; i<aSectionCount; i++) {
        if( [((PersonEntities*)self.JCDVC.clientEntitiesArray[0][i]).email isEqualToString:secondContact.email]){
            emailCount++;
        }
    }
    
    [self.JCDVC filterContentForSearchText:secondContact.email scope:nil];
    XCTAssertTrue(emailCount==[((NSArray*)self.JCDVC.clientEntitiesSearchArray[0]) count], @"clientEntitiesSearchArray should contain only nameCount contact(s)");

    
    
}


@end
