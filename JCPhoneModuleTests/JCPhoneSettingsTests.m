//
//  JCPhoneSettingsTests.m
//  JiveOne
//
//  Created by Robert Barclay on 8/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneModuleTesting.h"

#import "JCPhoneSettings.h"

SpecBegin(PhoneSettings)

describe(@"Setters", ^{
    
    __block id userDefaults = mock([NSUserDefaults class]);
    __block JCPhoneSettings *settings = [[JCPhoneSettings alloc] initWithDefaults:userDefaults];
    
    expect(settings).toNot.beNil;
    expect(settings.userDefaults).toNot.beNil;
    
    
    
    
});


SpecEnd


@interface JCPhoneSettings ()

-(instancetype)initWithDefaults:(NSUserDefaults *)userDefaults;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@interface JCPhoneSettingsTests : XCTestCase

@property (nonatomic, strong) JCPhoneSettings *settings;

@end

@implementation JCPhoneSettingsTests

- (void)setUp {
    [super setUp];
    
    id userDefaults = mock([NSUserDefaults class]);
    JCPhoneSettings *settings = [[JCPhoneSettings alloc] initWithDefaults:userDefaults];
    XCTAssertEqual(userDefaults, settings.userDefaults);
    self.settings = settings;
}

- (void)tearDown {
    self.settings = nil;
    [super tearDown];
}

//- (void)test_intercomEnabled_read {
//
//    NSString *key = @"intercomEnabled";
//    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
//    BOOL result = self.appSettings.isIntercomEnabled;
//    assertThatBool(result, isFalse());
//
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
//    result = self.appSettings.isIntercomEnabled;
//    assertThatBool(result, isTrue());
//}
//
//- (void)test_intercomMicrophoneMuteEnabled_read {
//
//    NSString *key = @"intercomMicrophoneMuteEnabled";
//    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
//    BOOL result = self.appSettings.isIntercomMicrophoneMuteEnabled;
//    assertThatBool(result, isFalse());
//
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
//    result = self.appSettings.isIntercomMicrophoneMuteEnabled;
//    assertThatBool(result, isTrue());
//}
//
//- (void)test_wifiOnly_read {
//
//    NSString *key = @"wifiOnly";
//    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
//    BOOL result = self.appSettings.isWifiOnly;
//    assertThatBool(result, isFalse());
//
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
//    result = self.appSettings.isWifiOnly;
//    assertThatBool(result, isTrue());
//}
//
//- (void)test_presenceEnabled_read {
//
//    NSString *key = @"presenceEnabled";
//    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
//    BOOL result = self.appSettings.isPresenceEnabled;
//    assertThatBool(result, isFalse());
//
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
//    result = self.appSettings.isPresenceEnabled;
//    assertThatBool(result, isTrue());
//}
//
//- (void)test_vibrateOnRing_read {
//
//    NSString *key = @"vibrateOnRing";
//    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
//    BOOL result = self.appSettings.isVibrateOnRing;
//    assertThatBool(result, isFalse());
//
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
//    result = self.appSettings.isVibrateOnRing;
//    assertThatBool(result, isTrue());
//}
//
//-(void)test_isVoicemailOnSpeaker_read {
//     NSString *key = @"voicemailOnSpeaker";
//    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:NO];
//    BOOL result = self.appSettings.voicemailOnSpeaker;
//    assertThatBool(result, isFalse());
//
//    [given([mockUserDefaults boolForKey:key]) willReturnBool:YES];
//    result = self.appSettings.voicemailOnSpeaker;
//    assertThatBool(result, isTrue());
//}
//
//-(void)test_volumeLevel_read {
//    NSString *key = @"volumeLevel";
//    NSUserDefaults *mockUserDefaults = self.appSettings.userDefaults;
//    [given([mockUserDefaults floatForKey:key]) willReturnFloat:0.123];
//
//    float result = self.appSettings.volumeLevel;
//    float value = 0.123;
//    assertThatFloat(result,equalToFloat(value));
//
//}

@end
