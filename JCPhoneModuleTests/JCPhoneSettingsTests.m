//
//  JCPhoneSettingsTests.m
//  JiveOne
//
//  Created by Robert Barclay on 8/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneModuleTesting.h"

#import "JCPhoneSettings.h"
#import "JCPhoneManager.h"

SpecBegin(JCPhoneSettings)

describe(@"Phone Settings", ^{
    
    __block NSUserDefaults *userDefaults;
    __block JCPhoneSettings *settings;
    
    beforeEach(^{
        userDefaults = OCMClassMock([NSUserDefaults class]);
        settings = [[JCPhoneSettings alloc] initWithDefaults:userDefaults];
        
        expect(settings).toNot.beNil;
        expect(settings.userDefaults).toNot.beNil;
    });
    
    context(@"phone enabled", ^{
        
        NSString *key = NSStringFromSelector(@selector(isPhoneEnabled));
        
        it(@"can read false value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(NO);
            BOOL result = settings.isPhoneEnabled;
            expect(result).to.beFalsy();
        });
        
        it(@"can read true value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(YES);
            BOOL result = settings.isPhoneEnabled;
            expect(result).to.beTruthy();
        });
        
        it(@"can write false value", ^{
            settings.phoneEnabled = FALSE;
            OCMVerify([userDefaults setBool:FALSE forKey:key]);
        });
        
        it(@"can write true value", ^{
            settings.phoneEnabled = TRUE;
            OCMVerify([userDefaults setBool:TRUE forKey:key]);
        });
    });
    
    context(@"do not disturb enabled", ^{
        
        NSString *key = NSStringFromSelector(@selector(isDoNotDisturbEnabled));
        
        it(@"can read false value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(NO);
            BOOL result = settings.isDoNotDisturbEnabled;
            expect(result).to.beFalsy();
        });
        
        it(@"can read true value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(YES);
            BOOL result = settings.isDoNotDisturbEnabled;
            expect(result).to.beTruthy();
        });
        
        it(@"can write false value", ^{
            settings.doNotDisturbEnabled = FALSE;
            OCMVerify([userDefaults setBool:FALSE forKey:key]);
        });
        
        it(@"can write true value", ^{
            settings.doNotDisturbEnabled = TRUE;
            OCMVerify([userDefaults setBool:TRUE forKey:key]);
        });
    });
    
    context(@"wifi only", ^{
        
        NSString *key = NSStringFromSelector(@selector(isWifiOnly));
        
        it(@"can read false value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(NO);
            BOOL result = settings.isWifiOnly;
            expect(result).to.beFalsy();
        });
        
        it(@"can read true value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(YES);
            BOOL result = settings.isWifiOnly;
            expect(result).to.beTruthy();
        });
        
        it(@"can write false value", ^{
            settings.wifiOnly = FALSE;
            OCMVerify([userDefaults setBool:FALSE forKey:key]);
        });
        
        it(@"can write true value", ^{
            settings.wifiOnly = TRUE;
            OCMVerify([userDefaults setBool:TRUE forKey:key]);
        });
    });
    
    context(@"vibrate on ring", ^{
        
        NSString *key = NSStringFromSelector(@selector(isVibrateOnRing));
        
        it(@"can read false value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(NO);
            BOOL result = settings.isVibrateOnRing;
            expect(result).to.beFalsy();
        });
        
        it(@"can read true value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(YES);
            BOOL result = settings.isVibrateOnRing;
            expect(result).to.beTruthy();
        });
        
        it(@"can write false value", ^{
            settings.vibrateOnRing = FALSE;
            OCMVerify([userDefaults setBool:FALSE forKey:key]);
        });
        
        it(@"can write true value", ^{
            settings.vibrateOnRing = TRUE;
            OCMVerify([userDefaults setBool:TRUE forKey:key]);
        });
    });
    
    context(@"intercom enabled", ^{
        
        NSString *key = NSStringFromSelector(@selector(isIntercomEnabled));
        
        it(@"can read false value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(NO);
            BOOL result = settings.isIntercomEnabled;
            expect(result).to.beFalsy();
        });
        
        it(@"can read true value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(YES);
            BOOL result = settings.isIntercomEnabled;
            expect(result).to.beTruthy();
        });
        
        it(@"can write false value", ^{
            settings.intercomEnabled = FALSE;
            OCMVerify([userDefaults setBool:FALSE forKey:key]);
        });
        
        it(@"can write true value", ^{
            settings.intercomEnabled = TRUE;
            OCMVerify([userDefaults setBool:TRUE forKey:key]);
        });
    });
    
    context(@"intercom microphone mute enabled", ^{
        
        NSString *key = NSStringFromSelector(@selector(isIntercomMicrophoneMuteEnabled));
        
        it(@"can read false value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(NO);
            BOOL result = settings.isIntercomMicrophoneMuteEnabled;
            expect(result).to.beFalsy();
        });
        
        it(@"can read true value", ^{
            OCMStub([userDefaults boolForKey:key]).andReturn(YES);
            BOOL result = settings.isIntercomMicrophoneMuteEnabled;
            expect(result).to.beTruthy();
        });
        
        it(@"can write false value", ^{
            settings.intercomMicrophoneMuteEnabled = FALSE;
            OCMVerify([userDefaults setBool:FALSE forKey:key]);
        });
        
        it(@"can write true value", ^{
            settings.intercomMicrophoneMuteEnabled = TRUE;
            OCMVerify([userDefaults setBool:TRUE forKey:key]);
        });
    });
    
    context(@"volume level", ^{
        
        NSString *key = NSStringFromSelector(@selector(volumeLevel));
        
        it(@"can read float value", ^{
            OCMStub([userDefaults floatForKey:key]).andReturn(0.6234);
            float result = settings.volumeLevel;
            expect(result).to.equal(0.6234);
        });
        
        it(@"can write float value", ^{
            settings.volumeLevel = 0.54321;
            OCMVerify([userDefaults setFloat:0.54321 forKey:key]);
        });
    });
    
    context(@"ringtone", ^{
        
        NSString *key = NSStringFromSelector(@selector(ringtone));
        
        it(@"can read string value", ^{
            OCMStub([userDefaults valueForKey:key]).andReturn(@"Fred");
            NSString *result = settings.ringtone;
            expect(result).to.equal(@"Fred");
        });
        
        it(@"can write string value", ^{
            settings.ringtone = @"Joe";
            OCMVerify([userDefaults setValue:@"Joe" forKey:key]);
        });
    });
});

describe(@"JCPhoneSettings UIViewController helper method", ^{
    
    __block UIViewController *vc;
    __block JCPhoneSettings *settings;
    
    beforeAll(^{
        settings = OCMClassMock([JCSettings class]);
        vc = [UIViewController new];
        vc.phoneManager = [[JCPhoneManager alloc] initWithSipManager:nil settings:settings reachability:nil];
    });
    
    
    
});


SpecEnd

