//
//  JCOsgiClientTest.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCOsgiClient.h"
#import "TRVSMonitor.h"
#import "JCAuthenticationManager.h"
#import <OCMock/OCMock.h>
#import "Common.h"
#import "JCLoginViewController.h"
#import "PersonEntities+Custom.h"
#import "Company.h"


@interface JCOsgiClientTest : XCTestCase

@property (nonatomic, strong) JCLoginViewController *loginViewController;

@end

@implementation JCOsgiClientTest
{
    NSString *barName;
    NSString *barConversation;
    NSString *entitiesString;
    NSString *companyString;
}

- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.loginViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"JCLoginViewController"];
    
    entitiesString = @"{\"ETag\":16321,\"me\":\"entities:egueiros\",\"entries\":[{\"lastModified\":1398118047363,\"meta\":{\"__v\":7,\"_id\":\"meta:entities:jmorris\",\"entity\":\"entities:jmorris\",\"lastModified\":1399588337644,\"createdDate\":1398118047343,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\",\"conversations:4217\",\"conversations:4217\",\"conversations:4535\",\"conversations:4535\",\"conversations:11086\",\"conversations:11086\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:jmorris\",\"id\":\"meta:entities:jmorris\"},\"presence\":\"presence:entities:jmorris\",\"company\":\"companies:jive\",\"_id\":\"entities:jmorris\",\"externalId\":\"jmorris\",\"__v\":0,\"createdDate\":1398118047339,\"sindex\":{\"nameSearch\":{\"counts\":{\"MRS\":1},\"ngrams\":[{\"_id\":\"5355969fe422b493225f66df\",\"ngram\":[\"MRS\"],\"id\":\"5355969fe422b493225f66df\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Jessie\",\"last\":\"Morris\",\"lastFirst\":\"Morris, Jessie\",\"firstLast\":\"Jessie Morris\"},\"groups\":[],\"urn\":\"entities:jmorris\",\"id\":\"entities:jmorris\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118047914,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:nwheeler\",\"entity\":\"entities:nwheeler\",\"lastModified\":1398118054691,\"createdDate\":1398118047887,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:nwheeler\",\"id\":\"meta:entities:nwheeler\"},\"presence\":\"presence:entities:nwheeler\",\"email\":\"nwheeler@jive.com\",\"_id\":\"entities:nwheeler\",\"externalId\":\"nwheeler\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047880,\"sindex\":{\"nameSearch\":{\"counts\":{\"WLR\":1},\"ngrams\":[{\"_id\":\"5355969fe422b493225f66e0\",\"ngram\":[\"WLR\"],\"id\":\"5355969fe422b493225f66e0\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Neil\",\"last\":\"Wheeler\",\"lastFirst\":\"Wheeler, Neil\",\"firstLast\":\"Neil Wheeler\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:nwheeler\",\"id\":\"entities:nwheeler\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118047926,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:asalazar\",\"entity\":\"entities:asalazar\",\"lastModified\":1398118054700,\"createdDate\":1398118047892,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:asalazar\",\"id\":\"meta:entities:asalazar\"},\"presence\":\"presence:entities:asalazar\",\"email\":\"asalazar@jive.com\",\"_id\":\"entities:asalazar\",\"externalId\":\"asalazar\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047889,\"sindex\":{\"nameSearch\":{\"counts\":{\"SLSR\":1},\"ngrams\":[{\"_id\":\"5355969fe422b493225f66e2\",\"ngram\":[\"SLSR\"],\"id\":\"5355969fe422b493225f66e2\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Anne\",\"last\":\"Salazar\",\"lastFirst\":\"Salazar, Anne\",\"firstLast\":\"Anne Salazar\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:asalazar\",\"id\":\"entities:asalazar\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118047919,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:mjensen\",\"entity\":\"entities:mjensen\",\"lastModified\":1398118054680,\"createdDate\":1398118047883,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:mjensen\",\"id\":\"meta:entities:mjensen\"},\"presence\":\"presence:entities:mjensen\",\"email\":\"mjensen@jive.com\",\"_id\":\"entities:mjensen\",\"externalId\":\"mjensen\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047876,\"sindex\":{\"nameSearch\":{\"counts\":{\"JNSN\":1},\"ngrams\":[{\"_id\":\"5355969fe422b493225f66e1\",\"ngram\":[\"JNSN\"],\"id\":\"5355969fe422b493225f66e1\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Malishya\",\"last\":\"Jensen\",\"lastFirst\":\"Jensen, Malishya\",\"firstLast\":\"Malishya Jensen\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:mjensen\",\"id\":\"entities:mjensen\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118047964,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:pthatcher\",\"entity\":\"entities:pthatcher\",\"lastModified\":1398118054709,\"createdDate\":1398118047928,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:pthatcher\",\"id\":\"meta:entities:pthatcher\"},\"presence\":\"presence:entities:pthatcher\",\"email\":\"pthatcher@jive.com\",\"_id\":\"entities:pthatcher\",\"externalId\":\"pthatcher\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047901,\"sindex\":{\"nameSearch\":{\"counts\":{\"0TKSHR\":1},\"ngrams\":[{\"_id\":\"5355969fe422b493225f66e3\",\"ngram\":[\"0TKSHR\"],\"id\":\"5355969fe422b493225f66e3\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Paul\",\"last\":\"Thatcher\",\"lastFirst\":\"Thatcher, Paul\",\"firstLast\":\"Paul Thatcher\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:pthatcher\",\"id\":\"entities:pthatcher\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118047978,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:rreeves\",\"entity\":\"entities:rreeves\",\"lastModified\":1398118054722,\"createdDate\":1398118047953,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:rreeves\",\"id\":\"meta:entities:rreeves\"},\"presence\":\"presence:entities:rreeves\",\"email\":\"rreeves@jive.com\",\"_id\":\"entities:rreeves\",\"externalId\":\"rreeves\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047933,\"sindex\":{\"nameSearch\":{\"counts\":{\"RFS\":1},\"ngrams\":[{\"_id\":\"5355969fe422b493225f66e4\",\"ngram\":[\"RFS\"],\"id\":\"5355969fe422b493225f66e4\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Rachel\",\"last\":\"Reeves\",\"lastFirst\":\"Reeves, Rachel\",\"firstLast\":\"Rachel Reeves\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:rreeves\",\"id\":\"entities:rreeves\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048005,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:g0ngfu@yahoo_com\",\"entity\":\"entities:g0ngfu@yahoo_com\",\"lastModified\":1398118054728,\"createdDate\":1398118047966,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:g0ngfu@yahoo_com\",\"id\":\"meta:entities:g0ngfu@yahoo_com\"},\"presence\":\"presence:entities:g0ngfu@yahoo_com\",\"email\":\"g0ngfu@yahoo.com\",\"_id\":\"entities:g0ngfu@yahoo_com\",\"externalId\":\"g0ngfu@yahoo.com\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047949,\"sindex\":{\"nameSearch\":{\"counts\":{\"FRT\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66e5\",\"ngram\":[\"FRT\"],\"id\":\"535596a0e422b493225f66e5\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Henry\",\"last\":\"Ford\",\"lastFirst\":\"Ford, Henry\",\"firstLast\":\"Henry Ford\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:g0ngfu@yahoo_com\",\"id\":\"entities:g0ngfu@yahoo_com\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048015,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:tbarton\",\"entity\":\"entities:tbarton\",\"lastModified\":1398118054753,\"createdDate\":1398118047983,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:tbarton\",\"id\":\"meta:entities:tbarton\"},\"presence\":\"presence:entities:tbarton\",\"email\":\"tbarton@jive.com\",\"_id\":\"entities:tbarton\",\"externalId\":\"tbarton\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047968,\"sindex\":{\"nameSearch\":{\"counts\":{\"BRTN\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66e6\",\"ngram\":[\"BRTN\"],\"id\":\"535596a0e422b493225f66e6\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Trevor\",\"last\":\"Barton\",\"lastFirst\":\"Barton, Trevor\",\"firstLast\":\"Trevor Barton\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:tbarton\",\"id\":\"entities:tbarton\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048042,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:msaltern\",\"entity\":\"entities:msaltern\",\"lastModified\":1398118054762,\"createdDate\":1398118047996,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:msaltern\",\"id\":\"meta:entities:msaltern\"},\"presence\":\"presence:entities:msaltern\",\"email\":\"msaltern@jive.com\",\"_id\":\"entities:msaltern\",\"externalId\":\"msaltern\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118047987,\"sindex\":{\"nameSearch\":{\"counts\":{\"SLTRN\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66e7\",\"ngram\":[\"SLTRN\"],\"id\":\"535596a0e422b493225f66e7\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Mark\",\"last\":\"Saltern\",\"lastFirst\":\"Saltern, Mark\",\"firstLast\":\"Mark Saltern\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:msaltern\",\"id\":\"entities:msaltern\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048051,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:jrobles\",\"entity\":\"entities:jrobles\",\"lastModified\":1398118054772,\"createdDate\":1398118048020,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:jrobles\",\"id\":\"meta:entities:jrobles\"},\"presence\":\"presence:entities:jrobles\",\"email\":\"jrobles@getjive.com\",\"_id\":\"entities:jrobles\",\"externalId\":\"jrobles\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118048006,\"sindex\":{\"nameSearch\":{\"counts\":{\"RBLS\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66e8\",\"ngram\":[\"RBLS\"],\"id\":\"535596a0e422b493225f66e8\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Jason\",\"last\":\"Robles\",\"lastFirst\":\"Robles, Jason\",\"firstLast\":\"Jason Robles\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:jrobles\",\"id\":\"entities:jrobles\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048078,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:sroche@jive_com\",\"entity\":\"entities:sroche@jive_com\",\"lastModified\":1398118054780,\"createdDate\":1398118048037,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:sroche@jive_com\",\"id\":\"meta:entities:sroche@jive_com\"},\"presence\":\"presence:entities:sroche@jive_com\",\"email\":\"sroche@jive.com\",\"_id\":\"entities:sroche@jive_com\",\"externalId\":\"sroche@jive.com\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118048025,\"sindex\":{\"nameSearch\":{\"counts\":{\"RKSH\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66e9\",\"ngram\":[\"RKSH\"],\"id\":\"535596a0e422b493225f66e9\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Steve\",\"last\":\"Roche\",\"lastFirst\":\"Roche, Steve\",\"firstLast\":\"Steve Roche\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:sroche@jive_com\",\"id\":\"entities:sroche@jive_com\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048101,\"meta\":{\"__v\":2,\"_id\":\"meta:entities:cshields\",\"entity\":\"entities:cshields\",\"lastModified\":1399597736154,\"createdDate\":1398118048071,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\",\"permanentrooms:12164\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:cshields\",\"id\":\"meta:entities:cshields\"},\"presence\":\"presence:entities:cshields\",\"email\":\"cshields@getjive.com\",\"_id\":\"entities:cshields\",\"externalId\":\"cshields\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118048062,\"sindex\":{\"nameSearch\":{\"counts\":{\"SHLTS\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66ea\",\"ngram\":[\"SHLTS\"],\"id\":\"535596a0e422b493225f66ea\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Colton\",\"last\":\"Shields\",\"lastFirst\":\"Shields, Colton\",\"firstLast\":\"Colton Shields\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:cshields\",\"id\":\"entities:cshields\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048111,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:ewalczak\",\"entity\":\"entities:ewalczak\",\"lastModified\":1398118054786,\"createdDate\":1398118048055,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:ewalczak\",\"id\":\"meta:entities:ewalczak\"},\"presence\":\"presence:entities:ewalczak\",\"email\":\"ewalczak@jive.com\",\"_id\":\"entities:ewalczak\",\"externalId\":\"ewalczak\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118048043,\"sindex\":{\"nameSearch\":{\"counts\":{\"WLKSK\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66eb\",\"ngram\":[\"WLKSK\"],\"id\":\"535596a0e422b493225f66eb\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Erik\",\"last\":\"Walczak\",\"lastFirst\":\"Walczak, Erik\",\"firstLast\":\"Erik Walczak\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:ewalczak\",\"id\":\"entities:ewalczak\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048141,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:smarshall\",\"entity\":\"entities:smarshall\",\"lastModified\":1398118054805,\"createdDate\":1398118048096,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:smarshall\",\"id\":\"meta:entities:smarshall\"},\"presence\":\"presence:entities:smarshall\",\"email\":\"smarshall@getjive.com\",\"_id\":\"entities:smarshall\",\"externalId\":\"smarshall\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118048088,\"sindex\":{\"nameSearch\":{\"counts\":{\"MRKSHL\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66ec\",\"ngram\":[\"MRKSHL\"],\"id\":\"535596a0e422b493225f66ec\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Scott\",\"last\":\"Marshall\",\"lastFirst\":\"Marshall, Scott\",\"firstLast\":\"Scott Marshall\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:smarshall\",\"id\":\"entities:smarshall\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118048160,\"meta\":{\"__v\":1,\"_id\":\"meta:entities:ajohnson\",\"entity\":\"entities:ajohnson\",\"lastModified\":1398118054813,\"createdDate\":1398118048123,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:ajohnson\",\"id\":\"meta:entities:ajohnson\"},\"presence\":\"presence:entities:ajohnson\",\"email\":\"ajohnson@getjive.com\",\"_id\":\"entities:ajohnson\",\"externalId\":\"ajohnson\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118048112,\"sindex\":{\"nameSearch\":{\"counts\":{\"JNSN\":1},\"ngrams\":[{\"_id\":\"535596a0e422b493225f66ed\",\"ngram\":[\"JNSN\"],\"id\":\"535596a0e422b493225f66ed\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Andrea\",\"last\":\"Johnson\",\"lastFirst\":\"Johnson, Andrea\",\"firstLast\":\"Andrea Johnson\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:ajohnson\",\"id\":\"entities:ajohnson\",\"picture\":\"/public/img/avatar.png\"},{\"lastModified\":1398118051683,\"meta\":{\"__v\":3,\"_id\":\"meta:entities:jivetesting13@gmail_com\",\"entity\":\"entities:jivetesting13@gmail_com\",\"lastModified\":1398371562930,\"createdDate\":1398118051641,\"pinnedActivityOrder\":[],\"activityOrder\":[\"permanentrooms:1104\",\"conversations:5410\",\"conversations:5410\"],\"favoriteEntities\":[],\"urn\":\"meta:entities:jivetesting13@gmail_com\",\"id\":\"meta:entities:jivetesting13@gmail_com\"},\"presence\":\"presence:entities:jivetesting13@gmail_com\",\"email\":\"jivetesting13@gmail.com\",\"_id\":\"entities:jivetesting13@gmail_com\",\"externalId\":\"jivetesting13@gmail.com\",\"company\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118051623,\"sindex\":{\"nameSearch\":{\"counts\":{\"13\":1,\"TSTNK\":1},\"ngrams\":[{\"_id\":\"535596a3e422b493225f67bf\",\"ngram\":[\"TSTNK\",\"13\"],\"id\":\"535596a3e422b493225f67bf\"}]}},\"tags\":[],\"location\":[0,0],\"name\":{\"first\":\"Jive\",\"last\":\"Testing 13\",\"lastFirst\":\"Testing 13, Jive\",\"firstLast\":\"Jive Testing 13\"},\"groups\":[\"groups:companies_jive\"],\"urn\":\"entities:jivetesting13@gmail_com\",\"id\":\"entities:jivetesting13@gmail_com\",\"picture\":\"/public/img/avatar.png\"}]}";
    companyString = @"{\"lastModified\":1398118046644,\"pbxId\":\"0127d974-f9f3-0704-2dee-000100420001\",\"timezone\":\"US/Mountain\",\"name\":\"Jive Communications, Inc.\",\"_id\":\"companies:jive\",\"__v\":0,\"createdDate\":1398118046639,\"urn\":\"companies:jive\",\"id\":\"companies:jive\"}";
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    [[TRVSMonitor monitor] signal];
}



- (void)testShouldRetrieveMyEntity
{
    NSString *expectedEmail = @"jivetesting13@gmail.com";
    NSString *expectedEntityId = @"entities:jivetesting13@gmail_com";
    
    id mockClient = [OCMockObject niceMockForClass:[JCOsgiClient class]];
    [[mockClient expect] RetrieveClientEntitites:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                 {
                                                     
                                                     //created hardcoded json object as a return object from the server
                                                     
                                                     NSData *responseObject = [entitiesString dataUsingEncoding:NSUTF8StringEncoding];
                                                     NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                     XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                     //because the method will add the json objects to core data and then populate JCVoicemailViewController.voicemails from core data, we need to make sure only our hard coded json object exists in core data
                                                     [PersonEntities MR_truncateAll];
                                                     //now add our hard coded json to core data
                                                     [PersonEntities addEntities:dictionary[@"entries"] me:expectedEntityId];
                                                     
                                                     successBlock(nil, entitiesString);
                                                     
                                                     return YES;

                                                     
                                                 }] failure:OCMOCK_ANY];
  
    [self.loginViewController setClient:mockClient];
    [self.loginViewController fetchEntities];
    
    [mockClient verify];
    
    PersonEntities *me = [PersonEntities MR_findFirstByAttribute:@"me" withValue:[NSNumber numberWithBool:YES]];
    XCTAssertNotNil(me, @"Should have returned my entity");
    XCTAssertEqualObjects(me.email, expectedEmail, @"Expected email and acquired email are different");
}

- (void)testShouldRetrieveMyCompany
{
    //[self testShouldRetrieveMyEntity];
    NSString *expectedCompanyId = @"companies:jive";
    NSString *expectedCompanyName = @"Jive Communications, Inc.";
    
    
    id mockClient = [OCMockObject niceMockForClass:[JCOsgiClient class]];

    [[mockClient expect] RetrieveMyCompany:expectedCompanyId :[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                  {
                                                      
                                                      //created hardcoded json object as a return object from the server
                                                      
                                                      NSData *responseObject = [companyString dataUsingEncoding:NSUTF8StringEncoding];
                                                      NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                      XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                      
                                                      [Company MR_truncateAll];
                                                      
                                                      NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
                                                      Company *company = [Company MR_createInContext:localContext];
                                                      company.lastModified = dictionary[@"lastModified"];
                                                      company.pbxId = dictionary[@"pbxId"];
                                                      company.timezone = dictionary[@"timezone"];
                                                      company.name = dictionary[@"name"];
                                                      company.urn = dictionary[@"urn"];
                                                      company.companyId = dictionary[@"id"];
                                                      
                                                      [localContext MR_saveToPersistentStoreAndWait];
                                                      
                                                      successBlock(nil, entitiesString);
                                                      
                                                      return YES;
                                                      
                                                      
                                                  }] failure:OCMOCK_ANY];
    
    [self.loginViewController setClient:mockClient];
    [self.loginViewController fetchCompany];
    
    [mockClient verify];

    //PersonEntities *me = [PersonEntities MR_findFirstByAttribute:@"me" withValue:[NSNumber numberWithBool:YES]];
    //XCTAssertNotNil(me, @"Should have returned my entity");
    
    Company *company = [Company MR_findFirst];
    XCTAssertNotNil(company, @"Should have returned my company");   
    XCTAssertEqualObjects(company.name, expectedCompanyName, @"Expected company name and acquired name are different");
}

- (void)testShouldRetrieveConversations
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *expectedChatRoomName = @"The Bar";
    
    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveConversations: %@", [err description]);
        [monitor signal];
    }];
     
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssertTrue(([response[@"entries"] count] > 0), @"Response should not have zero entries");
    
    
    NSString *givenChatRoomName;
    for (NSDictionary *entries in response[@"entries"]) {
        if (entries[@"name"]) {
            NSString *groupName = entries[@"name"];
            if ([groupName isEqualToString:expectedChatRoomName]) {
                givenChatRoomName = groupName;
                barConversation = entries[@"id"];
            }
        }
    }
    XCTAssertEqualObjects(givenChatRoomName, expectedChatRoomName, @"Response did not contain correct chat room name");
}

- (void)testShouldRequestSocketSession
{
    
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRequestSocketSession: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssert(response[@"urn"], @"Should Contain URN");
    XCTAssert(response[@"sessionToken"], @"Should Contain Session Token");
    XCTAssert(response[@"ws"], @"Should Contain WS");
}

- (void)testShouldSubscribeToSocketEventsWithAuthToken
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    
    
    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldSubscribeToSocketEventsWithAuthToken: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssert(response[@"urn"], @"Should Contain URN");
    XCTAssert(response[@"sessionToken"], @"Should Contain Session Token");
    XCTAssert(response[@"ws"], @"Should Contain WS");
    
    NSString *token = response[@"token"];
    NSDictionary* subscriptions = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
    
    response = nil;
    
    [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:token subscriptions:subscriptions success:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldSubscribeToSocketEventsWithAuthToken: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssert(response[@"urn"], @"Should Contain URN");
    XCTAssert(response[@"subscriptionUrn"], @"Should Contain Subscription URN");
    XCTAssert(response[@"session"], @"Should Contain Session");
    
}

- (void)testShouldSubmittChatMessageForConversation
{
    [self testShouldRetrieveConversations];
    
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *testConversation = barConversation;
    NSDictionary *testMessage = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Automated Test Message From %@ - %@ - %@", [[UIDevice currentDevice] name], [[UIDevice currentDevice] model], [NSDate date]], @"raw", nil];
    NSString *testEntity = @"entities:jivetesting13@gmail_com";
    long long testDate = [Common epochFromNSDate:[NSDate date]];
    NSString *tempUrn = @"tempUrn";
    
    [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:testConversation message:testMessage withEntity:testEntity withTimestamp:testDate withTempUrn:tempUrn success:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldSubmittChatMessageForConversation: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    
    NSString *givenMessage = response[@"message"][@"raw"];
    XCTAssertEqualObjects(givenMessage, testMessage, @"Message received should be same as message posted");
}

- (void)testShouldRetrieveClientEntities
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveClientEntities: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssertTrue(([response[@"entries"] count] > 0), @"Response should not have zero entries");
}
/**
 Tests RetrieveVoicemail Method
 This method creates a client entity by saving it to coredata - this is the only way to create a "me" entity when testing becasue we dont login with any specific credentials and thus dont have the [JCOmniPresence me]
 The Test Checks that the response object is not nil, that a random voicemail meta object from the responce object is not nil and, that a specific value for the "context" key is "outgoing"
 */
-(void)testShouldRetrieveVoicemail
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    NSDictionary* vmail1;
    
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    PersonEntities *me = [PersonEntities MR_createInContext:localContext];
    NSString *userId = @"jivetesting10@gmail.com";
    me.externalId = userId;
    [localContext MR_saveToPersistentStoreAndWait];
    
    [[JCOsgiClient sharedClient] RetrieveVoicemailForEntity:me success:^(id JSON){
        response = JSON;
        [monitor signal];
    }failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveVoicemail: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    
    NSArray *entries = response[@"entries"];
    if (entries && entries.count > 0) {
        vmail1 = entries[0];
        XCTAssertNotNil(vmail1, @"Response should not be nil");
        NSString *expectedContext = @"outgoing";
        NSString *givenContext = (NSString*)vmail1[@"context"];
        XCTAssertEqualObjects(givenContext, expectedContext, @"Response did not contain correct context value");
    }
    else {
        XCTAssertTrue(entries.count == 0, @"Should have no entries");
    }
    
}


@end
