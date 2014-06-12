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
    
    #define LOG_GENERAL(...) LogMessageF(__FILE__,__LINE__,__FUNCTION__,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],1,__VA_ARGS__)
#else
    
#define LOG_GENERAL(...)    do{}while(0)
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
    
    #define LOG_GENERAL(...) LogMessageF(__FILE__,__LINE__,__FUNCTION__,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],1,__VA_ARGS__)
#else
    
    //#define LOG_GENERAL(...)    do{}while(0)
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

