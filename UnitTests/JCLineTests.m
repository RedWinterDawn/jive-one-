//
//  JCLineTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"

#import "Line.h"
#import "PBX.h"

@interface JCLineTests : JCBaseTestCase

@end

@implementation JCLineTests

-(void)test_pbxId
{
    // Given
    NSString *expectedPbxId = @"01471162-f384-24f5-9351-000100420001";
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420001:014a5955-b837-e8d0-ab9a-000100620001";
    
    // When
    Line *line = [Line MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    //Thus
    XCTAssertNotNil(line, @"Jive Contact should not be nil");
    XCTAssertTrue([line isKindOfClass:[Line class]], @"Jive contact should be line");
    XCTAssertTrue([line.pbxId isEqualToString:expectedPbxId], @"Jive contact pbx id should equal the expected pbxId");
    XCTAssertTrue([line.pbx.pbxId isEqualToString:expectedPbxId], @"lines pbx's id should equal the expected pbxId");
}

-(void)test_detailedText
{
    
}

-(void)test_lineId
{
    
}

@end
