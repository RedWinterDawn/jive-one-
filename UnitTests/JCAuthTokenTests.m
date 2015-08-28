//
//  JCAuthInfoTests.m
//  JiveOne
//
//  Created by Robert Barclay on 8/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JiveOneTesting.h"

#import "JCAuthToken.h"

SpecBegin(JCAuthToken)

describe(@"JCAuthToken", ^{
  
    context(@"instantiation", ^{
        
        it(@"from nil URL", ^{
            expect(^{
                JCAuthToken *authInfo = [[JCAuthToken alloc] initWithUrl:nil];
                expect(authInfo).to.beNil();
            }).to.raiseAny();
        });
        
        context(@"from invalid URL", ^{
            
            __block NSString *urlString;
            
            it(@"has no user", ^{
                urlString = @"jiveclient://token#access_token=1&expires_in=604800000";
            });
            
            it(@"has empty user", ^{
                urlString = @"jiveclient://token#access_token=1&expires_in=604800000&username=";
            });
            
            it(@"has no access token", ^{
                urlString = @"jiveclient://token#&expires_in=604800000&username=1";
            });
            
            it(@"has empty access token", ^{
                urlString = @"jiveclient://token#access_token=&expires_in=604800000&username=1";
            });
            
            it(@"has no expiration interval", ^{
                urlString = @"jiveclient://token#access_token=1&username=1";
            });
            
            it(@"has empty expiration interval", ^{
                urlString = @"jiveclient://token#access_token=1&expires_in=&username=1";
            });
            
            it(@"has negative expiration interval", ^{
                urlString = @"jiveclient://token#access_token=1&expires_in=-1&username=1";
            });
            
            it(@"has error", ^{
                urlString = @"jiveclient://token#error=error";
            });
            
            afterEach(^{
                expect(^{
                    NSURL *url = [NSURL URLWithString:urlString];
                    JCAuthToken *authToken = [[JCAuthToken alloc] initWithUrl:url];
                    expect(authToken).to.beNil();
                }).to.raiseAny();
            });
        });
        
        context(@"from valid URL", ^{
            
            __block JCAuthToken *authToken;
            
            beforeEach(^{
                NSString *testUrl = @"jiveclient://token#access_token=1&expires_in=604800000&username=2";
                NSURL *url = [NSURL URLWithString:testUrl];
                authToken = [[JCAuthToken alloc] initWithUrl:url];
            });
            
            it(@"has username", ^{
                NSString *username = authToken.username;
                expect(username).toNot.beNil();
                expect(username).equal(@"2");
            });
            
            it(@"has auth token", ^{
                NSString *accessToken = authToken.accessToken;
                expect(accessToken).toNot.beNil();
                expect(accessToken).to.equal(@"1");
            });
            
            it(@"has expiration date", ^{
                NSDate *date = authToken.expirationDate;
                expect(date).toNot.beNil();
                expect(date).to.beKindOf([NSDate class]);
                
                NSTimeInterval interval = 604800000/1000;
                NSDate *expectedDate = [NSDate dateWithTimeIntervalSinceNow:interval];
                expect(date.description).to.equal(expectedDate.description);
                expect(round(date.timeIntervalSince1970)).to.equal(round(expectedDate.timeIntervalSince1970));
            });
            
            it(@"has authentication date", ^{
                NSDate *date = authToken.authenticationDate;
                expect(date).toNot.beNil();
                expect(date).to.beKindOf([NSDate class]);
                expect(date.description).to.equal([NSDate new].description);
                expect(round(date.timeIntervalSince1970)).to.equal(round([NSDate new].timeIntervalSince1970));
            });
            
            afterEach(^{
                authToken = nil;
            });
        });
        
        
        
        
        
//        it(@"from valid data", ^{
//            NSString *testUrl = @"jiveclient://token#access_token=1&expires_in=604800000&username=2";
//            NSURL *url = [NSURL URLWithString:testUrl];
//            JCAuthToken *authToken = [[JCAuthToken alloc] initWithUrl:url];
//            NSDictionary *dictionary = authToken.serializedDictionary;
//            NSData *data = authToken.serializedData;
//            
//            authToken = [[JCAuthToken alloc] initWithData:data];
//            expect(authToken).toNot.beNil;
//            expect(authToken.serializedDictionary).to.equal(dictionary);
//            expect(authToken.serializedData).to.equal(data);
//        });
//        
//        it(@"from null data", ^{
//            expect(^{
//                JCAuthToken *authInfo = [[JCAuthToken alloc] initWithData:nil];
//                expect(authInfo).to.beNil();
//            }).to.raiseAny();
//        });
//        
//        it(@"from invalid data", ^{
//            
//            NSString *string = @"bad data";
//            NSData *badData = [string dataUsingEncoding:NSUTF8StringEncoding];
//            expect(^{
//                JCAuthToken *authToken = [[JCAuthToken alloc] initWithData:badData];
//                expect(authToken).to.beNil();
//            }).to.raiseAny();
//            
//        });
        
//        context(@"from archive", ^{
//            
//            NSData *authToken;
//            
//            beforeEach(^{
//                NSString *testUrl = @"jiveclient://token#access_token=1&expires_in=604800000&username=2";
//                NSURL *url = [NSURL URLWithString:testUrl];
//                JCAuthToken *authToken = [[JCAuthToken alloc] initWithUrl:url];
//            });
//            
//            it(@"has username", ^{
//                NSString *username = authToken.username;
//                expect(username).toNot.beNil();
//                expect(username).equal(@"2");
//            });
//            
//            it(@"has auth token", ^{
//                NSString *accessToken = authToken.accessToken;
//                expect(accessToken).toNot.beNil();
//                expect(accessToken).to.equal(@"1");
//            });
//            
//            it(@"has expiration date", ^{
//                NSDate *date = authToken.expirationDate;
//                expect(date).toNot.beNil();
//                expect(date).to.beKindOf([NSDate class]);
//                
//                NSTimeInterval interval = 604800000/1000;
//                NSDate *expectedDate = [NSDate dateWithTimeIntervalSinceNow:interval];
//                expect(date.description).to.equal(expectedDate.description);
//                expect(round(date.timeIntervalSince1970)).to.equal(round(expectedDate.timeIntervalSince1970));
//            });
//            
//            it(@"has authentication date", ^{
//                NSDate *date = authToken.authenticationDate;
//                expect(date).toNot.beNil();
//                expect(date).to.beKindOf([NSDate class]);
//                expect(date.description).to.equal([NSDate new].description);
//                expect(round(date.timeIntervalSince1970)).to.equal(round([NSDate new].timeIntervalSince1970));
//            });
//        });
//        
//        it(@"from null dictionary", ^{
//            expect(^{
//                JCAuthToken *authInfo = [[JCAuthToken alloc] initWithDictionary:nil];
//                expect(authInfo).to.beNil();
//            }).to.raiseAny();
//        });
        
    });
    
//    describe(@"serialization", ^{
//        
//        __block JCAuthToken *authToken;
//        __block NSDictionary *serializedData;
//        
//        beforeEach(^{
//            NSString *testUrl = @"jiveclient://token#access_token=1&expires_in=604800000&username=2";
//            NSURL *url = [NSURL URLWithString:testUrl];
//            authToken = [[JCAuthToken alloc] initWithUrl:url];
//            serializedData = authToken.serializedDictionary;
//        });
//        
//        it(@"has username", ^{
//            NSString *object = [serializedData objectForKey:kJCAuthInfoUsernameKey];
//            expect(object).toNot.beNil;
//            expect(object).to.beKindOf([NSString class]);
//            expect(object).to.equal(@"2");
//        });
//        
//        it(@"has access token", ^{
//            id object = [serializedData objectForKey:kJCAuthInfoAccessTokenKey];
//            expect(object).toNot.beNil;
//            expect(object).to.beKindOf([NSString class]);
//            expect(object).to.equal(@"1");
//        });
//        
//        it(@"has expiration date", ^{
//            id object = [serializedData objectForKey:kJCAuthInfoExpirationDateKey];
//            expect(object).toNot.beNil;
//            expect(object).to.beKindOf([NSNumber class]);
//            
//            NSTimeInterval interval = authToken.expirationDate.timeIntervalSince1970;
//            expect(object).to.equal(interval);
//        });
//        
//        it(@"has authentication date", ^{
//            id object = [serializedData objectForKey:kJCAuthInfoAuthenticationDateKey];
//            expect(object).toNot.beNil;
//            expect(object).to.beKindOf([NSNumber class]);
//            
//            NSTimeInterval interval = authToken.authenticationDate.timeIntervalSince1970;
//            expect(object).to.equal(interval);
//        });
//    });
});

SpecEnd
