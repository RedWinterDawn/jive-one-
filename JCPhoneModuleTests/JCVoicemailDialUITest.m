//
//  JCVoicemailDialUITest.m
//  JiveOne
//
//  Created by P Leonard on 8/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//
//  You prfex each test with test## becasue they are run alphabetically
//  so if a test depends on another incrent them in order.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <KIF/KIF.h>


@interface JCVoicemailDialUITest : KIFTestCase

@end

@implementation JCVoicemailDialUITest

-(void)beforeAll{
// if you need to set something up before all tests are exicuted you place it here
}

-(void)test01DialVoicemail
{
    [tester tapViewWithAccessibilityLabel:@"*"];
    [tester tapViewWithAccessibilityLabel:@"9"];
    [tester tapViewWithAccessibilityLabel:@"9"];
    [tester tapViewWithAccessibilityLabel:@"Dial Button"];
    [tester tapViewWithAccessibilityLabel:@"hangup"];
}

-(void)test02DoubleTabCallButtonToRedial{
    [tester tapViewWithAccessibilityLabel:@"Dial Button"];
    [tester tapViewWithAccessibilityLabel:@"Dial Button"];
}
@end
