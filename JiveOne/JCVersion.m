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

+ (JCVersion*)sharedClient {
    static JCVersion *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[super alloc] init];
        [_sharedClient initialize];
    });
    return _sharedClient;
}

-(void)initialize
{
    _delegate = self;
}

- (void)receivedData:(NSData *)data
{
    //determine that this is the first time the user has opened this install of the app and that version has a value
    NSLog(@"Build Version is: %i",version);
    if (version < 1) {
        NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        version = [[[stringData componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""] intValue];
        NSLog(@"Initial Build Version is: %i",version);
        [[NSUserDefaults standardUserDefaults] setInteger:version forKey:@"appBuildNumber"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }//else if version has a value - check to see if this install is the latest version.
    else if(version > 1)
    {
        NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        version = [[[stringData componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""] intValue];
        if (version > [[NSUserDefaults standardUserDefaults] integerForKey:@"appBuildNumber"]) {
            NSLog(@"Prompt for new install.");
            version--;
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AppIsOutdated" object:nil];
            });
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
    
    NSURLRequest *urlRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", kVersionURL]]
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:15.0];
    NSLog(@"RequestMadeWithOutUsingCache");
    
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", kVersionURL]];
//    
//    NSURLRequest *urlRequest = [[NSURLRequest requestWithURL:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
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
