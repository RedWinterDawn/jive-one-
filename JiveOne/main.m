//
//  main.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCAuthenticationManager.h"

#import "JCAppDelegate.h"

int main(int argc, char * argv[])
{
    int returnValue;
    
    @autoreleasepool {
        BOOL inTests = (NSClassFromString(@"SenTestCase") != nil
                        || NSClassFromString(@"XCTest") != nil);
        
        if (inTests) {
            //use a special empty delegate when we are inside the tests
            NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
            if (!(token && token.length)) {
                token = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
                if (!(token && token.length)) {
                    NSString *testToken = kTestAuthKey;
                    [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:testToken];
                }
            }
            //returnValue = UIApplicationMain(argc, argv, nil, @"TestsAppDelegate");
        }
        //else {
            //use the normal delegate
            returnValue = UIApplicationMain(argc, argv, nil, NSStringFromClass([JCAppDelegate class]));
        //}
    
    return returnValue;
    }
    
    
}

