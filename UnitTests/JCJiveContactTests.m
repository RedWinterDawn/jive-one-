//
//  JCJiveContactTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JiveContact.h"

@interface JCJiveContactTests : JCBaseTestCase

@end

@implementation JCJiveContactTests

-(void)test_pbxId_searchByPbxId
{
    NSString *pbxId = @"01471162-f384-24f5-9351-000100420001";
    NSArray *jiveContacts = [JiveContact MR_findByAttribute:NSStringFromSelector(@selector(pbxId)) withValue:pbxId];
    XCTAssertTrue(jiveContacts.count == 4, @"Incorrect count off Jive contacts");
}

@end
