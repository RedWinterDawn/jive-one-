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

#import "Line.h"
#import "PBX.h"
#import "User.h"

NSString *const kJCV4ProvisioningClientRequestUrl = @"https://pbx.onjive.com/p/mobility/mobileusersettings";
NSString *const kJCV4ProvisioningClientRequestString = @"<login \n user=\"%@\" \n password=\"%@\" \n man=\"Apple\" \n device=\"%@\" \n os=\"%@\" \n loc=\"%@\" \n lang=\"%@\" \n uuid=\"%@\" \n spid=\"cpc\" \n build=\"%@\" \n type=\"%@\" />";

@implementation JCV4ProvisioningRequest

+(NSMutableURLRequest *)requestWithLine:(Line *)line
{
    // Create the request
    NSURL *url = [NSURL URLWithString:kJCV4ProvisioningClientRequestUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    // Create Payload
    NSData *data = [JCV4ProvisioningRequest postBodyWithLine:line];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    return request;
}

+(NSData *)postBodyWithLine:(Line *)line
{
    NSString *payload = [JCV4ProvisioningRequest xmlProvisioningRequestWithLine:line];
    return [payload dataUsingEncoding:NSUTF8StringEncoding];
}

+(NSString *)xmlProvisioningRequestWithLine:(Line *)line
{
    if (!line) {
        [NSException raise:NSInvalidArgumentException format:@"Line is NULL"];
    }
    
    if (!line.pbx) {
        [NSException raise:NSInvalidArgumentException format:@"Line PBX is NULL"];
    }
    
    if (!line.pbx.user) {
        [NSException raise:NSInvalidArgumentException format:@"Line PBX User is NULL"];
    }
    
    if (!line.pbx.user.jiveUserId) {
        [NSException raise:NSInvalidArgumentException format:@"Jive User id is NULL"];
    }
    
    JCAuthenticationManager *authenticationManager = [JCAuthenticationManager sharedInstance];
    if (!authenticationManager.password) {
        [NSException raise:NSInvalidArgumentException format:@"Password is NULL"];
    }
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSLocale *local = [NSLocale currentLocale];
    UIDevice *device = [UIDevice currentDevice];
    
    NSString *username          = line.pbx.user.jiveUserId;
    NSString *password          = authenticationManager.password;
    NSString *language          = [[bundle preferredLocalizations] objectAtIndex:0];
    NSString *locale            = local.localeIdentifier;
    NSString *appBuildString    = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *model             = device.model;
    NSString *os                = device.systemVersion;
    NSString *uuid              = device.identifierForVendor.UUIDString;
    NSString *type              = device.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"ios.jive.phone" : @"ios.jive.tablet";
    
    return  [NSString stringWithFormat:kJCV4ProvisioningClientRequestString,
             username,
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

@end

@implementation JCV4ProvisioningClient

+(void)requestProvisioningForLine:(Line *)line completed:(void (^)(BOOL success, NSError * error))completed
{
    // Build Request
    NSURLRequest *request = nil;
    @try {
        request = [JCV4ProvisioningRequest requestWithLine:line];
    }
    @catch (NSException *exception) {
        completed(false, [JCV4ProvisioningError errorWithType:InvalidRequestParametersError reason:exception.reason]);
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Peform the request
        __autoreleasing NSURLResponse *response;
        __autoreleasing NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error) {
            completed(false, [JCV4ProvisioningError errorWithType:RequestResponseError reason:error.localizedFailureReason]);
            return;
        }
        
        // Process Response Data
        @try {
            NSDictionary *response = [NSDictionary dictionaryWithXMLData:data];
            [LineConfiguration addConfiguration:response line:line completed:^(BOOL success, NSError *error) {
                completed(success, error);
            }];
        }
        @catch (NSException *exception) {
            completed(NO, [JCV4ProvisioningError errorWithType:ResponseParseError reason:exception.reason]);
        }
    });
}

@end

NSString *const kJCV4ProvisioningErrorDomain = @"ProvisioningError";

@implementation JCV4ProvisioningError

+(instancetype)errorWithType:(JCV4ProvisioningErrorType)type reason:(NSString *)reason{
    return [JCV4ProvisioningError errorWithDomain:kJCV4ProvisioningErrorDomain code:type userInfo:@{NSLocalizedDescriptionKey:reason}];
}

@end
