//
//  JCContactsTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"

#import "InternalExtension.h"
#import "PBX.h"

@interface JCContactsTests : JCBaseTestCase

@end

@implementation JCContactsTests

-(void)test_pbxId
{
    // Given
    NSString *expectedPbxId = @"01471162-f384-24f5-9351-000100420001";
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420001:014a5955-b837-e8d0-ab9a-000100620002";
    
    // When
    InternalExtension *contact = [InternalExtension MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    //Thus
    XCTAssertNotNil(contact, @"Jive Contact should not be nil");
    XCTAssertTrue([contact isKindOfClass:[InternalExtension class]], @"Jive contact should be line");
    XCTAssertTrue([contact.pbxId isEqualToString:expectedPbxId], @"Jive contact pbx id should equal the expected pbxId");
    XCTAssertTrue([contact.pbx.pbxId isEqualToString:expectedPbxId], @"lines pbx's id should equal the expected pbxId");
}

@end
