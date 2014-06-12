//
//  main.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCAuthenticationManager.h"
#import "NSLogger.h"
#import "JCAppDelegate.h"

int main(int argc, char * argv[])
{

#ifdef CONFIGURATION_Debug
    LoggerStartForBuildUser();
    NSLog(@"%@",[[UIDevice currentDevice] name]);
#endif
    
    
#ifdef CONFIGURATION_Enterprise
     if ([[[UIDevice currentDevice]name] isEqualToString:@"iPhone Simulator"]) {
         LoggerStop(LoggerGetDefaultLogger());
         NSLog(@"Logger Stop Message Sent");
     }
     else
     {
         NSLog(@"Logger Start Message Sent");
         LoggerStartForBuildUser();
     }
#endif


    int returnValue;
    
    @autoreleasepool {
        @try {
            returnValue = UIApplicationMain(argc, argv, nil, NSStringFromClass([JCAppDelegate class]));
        }
        @catch (NSException* exception) {
            NSLog(@"Uncaught exception: %@", exception.description);
            NSLog(@"Stack trace: %@", [exception callStackSymbols]);
        }
    }
    return returnValue; 
    
}

