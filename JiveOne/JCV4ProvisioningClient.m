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

@implementation JCV4ProvisioningClient

+(void)requestProvisioningForLine:(Line *)line completed:(void (^)(BOOL success, NSError * error))completed
{
    // Build Request
    NSURLRequest *request = nil;
    @try {
        request = [JCV4ProvisioningURLRequest requestWithLine:line];
    }
    @catch (NSException *exception) {
        completed(false, [JCV4ProvisioningError errorWithType:JCV4ProvisioningInvalidRequestParametersError reason:exception.reason]);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Peform the request
        __autoreleasing NSURLResponse *response;
        __autoreleasing NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error) {
            completed(false, [JCV4ProvisioningError errorWithType:JCV4ProvisioningRequestResponseError reason:error.localizedDescription]);
            return;
        }
        
        // Process Response Data
        @try {
            NSDictionary *result = [NSDictionary dictionaryWithXMLData:data];
            if (!result) {
                completed(false, [JCV4ProvisioningError errorWithType:JCV4ProvisioningRequestResponseError reason:@"Response is Empty"]);
                return;
            }
            
            NSDictionary *status = [result valueForKeyPath:@"login_response.status"];
            NSString *success = [status stringValueForKey:@"_success"];
            if ([success isEqualToString:@"false"]) {
                completed(false, [JCV4ProvisioningError errorWithType:JCV4ProvisioningRequestResponseError reason:[status stringValueForKey:@"_error_text"]]);
                return;
            }
            
            NSArray *array = [result valueForKeyPath:@"branding.settings_data.core_data_list.account_list.account.data"];
            if (!array || array.count == 0) {
                completed(false, [JCV4ProvisioningError errorWithType:JCV4ProvisioningRequestResponseError reason:@"No Line Configuration present"]);
                return;
            }
            
            [LineConfiguration addLineConfigurations:array line:line completed:^(BOOL success, NSError *error) {
                completed(success, error);
            }];
        }
        @catch (NSException *exception) {
            completed(NO, [JCV4ProvisioningError errorWithType:JCV4ProvisioningResponseParseError reason:exception.reason]);
        }
    });
}

@end

#pragma mark - JCV4ProvisioningRequest -

NSString *const kJCV4ProvisioningClientRequestString = @"<login user=\"%@\" password=\"%@\" token=\"%@\" pbxid=\"%@\" line=\"%@\" man=\"Apple\" device=\"%@\" os=\"%@\" loc=\"%@\" lang=\"%@\" uuid=\"%@\" spid=\"cpc\" build=\"%@\" type=\"%@\" />";

@implementation JCV4ProvisioningRequest

+(NSData *)postDataForLine:(Line *)line
{
    
    JCV4ProvisioningRequest *request = [[JCV4ProvisioningRequest alloc] initWithUserName:line.pbx.user.jiveUserId
                                                                                password:nil
                                                                                   token:[JCAuthenticationManager sharedInstance].authToken
                                                                                   pbxId:line.pbx.pbxId
                                                                               extension:line.extension];
    return request.postData;
}

-(instancetype)initWithUserName:(NSString *)userName password:(NSString *)password token:(NSString *)token pbxId:(NSString *)pbxId extension:(NSString *)extension
{
    self = [self init];
    if (self) {
        
        if (!userName) {
            [NSException raise:NSInvalidArgumentException format:@"User is NULL"];
        }
        _userName = userName;
        
        if (!token) {
            [NSException raise:NSInvalidArgumentException format:@"Token is NULL"];
        }
        _token = token;
        
        if (!pbxId) {
            [NSException raise:NSInvalidArgumentException format:@"PBX is NULL"];
        }
        _pbxId = pbxId;
        
        if (!extension) {
            [NSException raise:NSInvalidArgumentException format:@"Extension is NULL"];
        }
        _extension = extension;
        _password = password ? password : @"";
    }
    return self;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSLocale *local = [NSLocale currentLocale];
        UIDevice *device = [UIDevice currentDevice];
        
        _language          = [[bundle preferredLocalizations] objectAtIndex:0];
        _locale            = local.localeIdentifier;
        _appBuildString    = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        _model             = device.model;
        _os                = device.systemVersion;
        _uuid              = device.identifierForVendor.UUIDString;
        _type              = device.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"ios.jive.phone" : @"ios.jive.tablet";
    }
    return self;
}

-(NSString *)xml
{
    return  [NSString stringWithFormat:kJCV4ProvisioningClientRequestString,
             _userName,
             _password,
             _token,
             _pbxId,
             _extension,
             _model,
             _os,
             _locale,
             _language,
             _uuid,
             _appBuildString,
             _type
             ];
}

-(NSData *)postData
{
    return [self.xml dataUsingEncoding:NSUTF8StringEncoding];
}

@end

#pragma mark - JCV4ProvisioningURLRequest -

NSString *const kJCV4ProvisioningClientRequestUrl = @"https://pbx.onjive.com/p/mobility/mobileusersettings";

@implementation JCV4ProvisioningURLRequest

+(NSMutableURLRequest *)requestWithLine:(Line *)line
{
    // Create the request
    NSURL *url = [NSURL URLWithString:kJCV4ProvisioningClientRequestUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    // Create Payload
    NSData *data = [JCV4ProvisioningRequest postDataForLine:line];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:[JCAuthenticationManager sharedInstance].authToken forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:data];
    return request;
}

@end

#pragma mark - JCV4ProvisioningError -

NSString *const kJCV4ProvisioningErrorDomain = @"ProvisioningError";

@implementation JCV4ProvisioningError

+(instancetype)errorWithType:(JCV4ProvisioningErrorType)type reason:(NSString *)reason{
    return [JCV4ProvisioningError errorWithDomain:kJCV4ProvisioningErrorDomain code:type userInfo:@{NSLocalizedDescriptionKey:reason}];
}



@end
