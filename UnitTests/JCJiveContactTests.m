//
//  JCJiveContactTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JiveContact.h"
#import "Line.h"
#import "PBX.h"

@interface JCJiveContactTests : JCBaseTestCase

@end

@implementation JCJiveContactTests

-(void)test_pbx_id
{
    // Given
    NSString *expectedPbxId = @"01471162-f384-24f5-9351-000100420001";
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420001:014a5955-b837-e8d0-ab9a-000100620001";
    
    // When
    JiveContact *jiveContact = [JiveContact MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    //Thus
    XCTAssertNotNil(jiveContact, @"Jive Contact should not be nil");
    XCTAssertTrue([jiveContact isKindOfClass:[Line class]], @"Jive contact should be line");
    XCTAssertTrue([jiveContact.pbxId isEqualToString:expectedPbxId], @"Jive contact pbx id should equal the expected pbxId");
    
    Line *line = (Line *)jiveContact;
    XCTAssertTrue([line.pbxId isEqualToString:expectedPbxId], @"line pbx id should equal the expected pbxId");
    XCTAssertTrue([line.pbx.pbxId isEqualToString:expectedPbxId], @"lines pbx's id should equal the expected pbxId");
}

@end
