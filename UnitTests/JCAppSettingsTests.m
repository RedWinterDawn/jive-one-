//
//  JCAppSettingsTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "JCAppSettings.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

@interface JCAppSettings ()

-(instancetype)initWithDefaults:(NSUserDefaults *)userDefaults;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@interface JCAppSettingsTests : XCTestCase

@property (nonatomic, strong) JCAppSettings *appSettings;

@end

@implementation JCAppSettingsTests

- (void)setUp {
    [super setUp];
    
    id userDefaults = mock([NSUserDefaults class]);
    JCAppSettings *appSettings = [[JCAppSettings alloc] initWithDefaults:userDefaults];
    XCTAssertEqual(userDefaults, appSettings.userDefaults);
    self.appSettings = appSettings;
}

- (void)tearDown {
    self.appSettings = nil;
    [super tearDown];
}

- (void)test_intercomEnabled_read {
    
    NSString *key = @"intercomEnabled";
    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
    BOOL result = self.appSettings.isIntercomEnabled;
    assertThatBool(result, isFalse());
    
    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
    result = self.appSettings.isIntercomEnabled;
    assertThatBool(result, isTrue());
}

- (void)test_intercomMicrophoneMuteEnabled_read {
    
    NSString *key = @"intercomMicrophoneMuteEnabled";
    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
    BOOL result = self.appSettings.isIntercomMicrophoneMuteEnabled;
    assertThatBool(result, isFalse());
    
    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
    result = self.appSettings.isIntercomMicrophoneMuteEnabled;
    assertThatBool(result, isTrue());
}

- (void)test_wifiOnly_read {
    
    NSString *key = @"wifiOnly";
    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
    BOOL result = self.appSettings.isWifiOnly;
    assertThatBool(result, isFalse());
    
    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
    result = self.appSettings.isWifiOnly;
    assertThatBool(result, isTrue());
}

- (void)test_presenceEnabled_read {
    
    NSString *key = @"presenceEnabled";
    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
    BOOL result = self.appSettings.isPresenceEnabled;
    assertThatBool(result, isFalse());
    
    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
    result = self.appSettings.isPresenceEnabled;
    assertThatBool(result, isTrue());
}

- (void)test_vibrateOnRing_read {
    
    NSString *key = @"vibrateOnRing";
    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
    BOOL result = self.appSettings.isVibrateOnRing;
    assertThatBool(result, isFalse());
    
    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
    result = self.appSettings.isVibrateOnRing;
    assertThatBool(result, isTrue());
}


@end
