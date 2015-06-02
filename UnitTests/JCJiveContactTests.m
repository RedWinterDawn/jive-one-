//
//  JCJiveContactTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "Extension.h"
#import "NSString+Additions.h"

@interface JCJiveContactTests : JCBaseTestCase

@end

@implementation JCJiveContactTests

-(void)test_pbxId_searchByPbxId
{
    NSString *pbxId = @"01471162-f384-24f5-9351-000100420001";
    NSArray *jiveContacts = [Extension MR_findByAttribute:NSStringFromSelector(@selector(pbxId)) withValue:pbxId];
    XCTAssertTrue(jiveContacts.count == 4, @"Incorrect count off Jive contacts");
}

- (void)test_detailText {
    
    // Given
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420002:014a5955-b837-e8d0-ab9a-000100620003";
    
    // When
    Extension *person = [Extension MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    // Thus
    XCTAssertNotNil(person, @"We should have a person");
//    NSString *expectedDetail = [NSString stringWithFormat:@"ext: %@", person.number.formattedPhoneNumber];
    NSString *detailText = person.detailText;
//    XCTAssertTrue([detailText isEqualToString:expectedDetail], @"detail text should equal");
}

@end
