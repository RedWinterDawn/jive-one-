	//
//  JCV4ProvisioningClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCV4ProvisioningClient.h"
#import "Common.h"
#import "LineConfiguration+Custom.h"
#import <XMLDictionary/XMLDictionary.h>

NSString *const kJCV4ProvisioningClientRequestUrl = @"https://pbx.onjive.com/p/mobility/mobileusersettings";

NSString *const kJCV4ProvisioningClientRequestString = @"<login \n user=\"%@\" \n password=\"%@\" \n man=\"Apple\" \n device=\"%@\" \n os=\"%@\" \n loc=\"%@\" \n lang=\"%@\" \n uuid=\"%@\" \n spid=\"cpc\" \n build=\"%@\" \n type=\"%@\" />";

@implementation JCV4ProvisioningClient

+(NSString *)xmlProvisioningRequestFor:(NSString *)userName password:(NSString *)password
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSLocale *local = [NSLocale currentLocale];
    UIDevice *device = [UIDevice currentDevice];
    
    
    NSString *language          = [[bundle preferredLocalizations] objectAtIndex:0];
    NSString *locale            = local.localeIdentifier;
    NSString *appBuildString    = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *model             = device.model;
    NSString *os                = device.systemVersion;
    NSString *uuid              = device.identifierForVendor.UUIDString;
    NSString *type              = device.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"ios.jive.phone" : @"ios.jive.tablet";
    
    return  [NSString stringWithFormat:kJCV4ProvisioningClientRequestString,
             userName,
             password,
             model,
             os,
             locale,
             language,
             uuid,
             appBuildString,
             type
             ];
}

+(void)requestProvisioningForUser:(NSString *)user password:(NSString *)password completed:(void (^)(BOOL suceeded, NSError *error))completed
{
    NSString *payload = [JCV4ProvisioningClient xmlProvisioningRequestFor:user password:password];
    NSData *postData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:kJCV4ProvisioningClientRequestUrl];
    
    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Peform the request
        __autoreleasing NSURLResponse *response;
        __autoreleasing NSError *error = nil;
        NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error) {
            return;
        }
        
        @try {
            NSDictionary *response = [NSDictionary dictionaryWithXMLData:receivedData];
            [LineConfiguration addConfiguration:response completed:^(BOOL success) {
                completed(YES, nil);
            }];
        }
        @catch (NSException *exception) {
            completed(NO, [NSError errorWithDomain:exception.reason code:0 userInfo:nil]);
        }
    });
}

@end
