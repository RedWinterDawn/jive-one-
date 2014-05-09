//
//  JCVersion.m
//  JiveOne
//
//  Created by Doug on 5/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVersion.h"

@implementation JCVersion
{
    NSMutableData *receivedData;
    NSURLConnection *theConnection;
    int version;
}


-(void)initialize
{
    _delegate = self;
}

- (void)receivedData:(NSData *)data
{
    //determine that this is the first time the user has opened this install of the app and that version has a value
    if (version < 1) {
        NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        version = [[[stringData componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""] intValue];
        [[NSUserDefaults standardUserDefaults] setInteger:version forKey:@"appBuildNumber"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }//else if version has a value - check to see if this install is the latest version.
    else if((version > 1))
    {
        NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        version = [[[stringData componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""] intValue];
        if (version > [[NSUserDefaults standardUserDefaults] integerForKey:@"appBuildNumber"]) {
            NSLog(@"Prompt for new install.");
        }
    }
}
- (void)emptyReply
{
    
}
- (void)timedOut
{
    
}

- (void)downloadError
{
    
}


-(void)getVersion
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kVersionURL]];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if ([data length] > 0 && error == nil)
             [self.delegate receivedData:data];
         else if ([data length] == 0 && error == nil)
             [self.delegate emptyReply];
         else if (error != nil)
             [self.delegate downloadError];
     }];
    
}

@end
