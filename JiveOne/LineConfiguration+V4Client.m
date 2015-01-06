//
//  LineConfiguration+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration+V4Client.h"
#import "PBX.h"
#import "JCV4Client.h"

#import "NSDictionary+Validations.h"
#import "NSString+MD5Additions.h"

#define LINE_CONFIGURATION_REQUEST_TIMEOUT 60

NSString *const kLineConfigurationRequestPath = @"/p/mobility/mobileusersettings";

NSString *const kLineConfigurationRequestXMLString = @"<login user=\"%@\" password=\"\" token=\"%@\" pbxid=\"%@\" line=\"%@\" man=\"Apple\" device=\"%@\" os=\"%@\" loc=\"%@\" lang=\"%@\" uuid=\"%@\" spid=\"cpc\" build=\"%@\" type=\"%@\" />";

NSString *const kJCLineConfigurationRequestUsernameKey      = @"username";
NSString *const kJCLineConfigurationRequestPbxIdKey         = @"pbxId";
NSString *const kJCLineConfigurationRequestExtensionKey     = @"extension";
NSString *const kJCLineConfigurationRequestDeviceTypePhone  = @"ios.jive.phone";
NSString *const kJCLineConfigurationRequestDeviceTypeTablet = @"ios.jive.tablet";


NSString *const kLineConfigurationResponseKey                   = @"_name";
NSString *const kLineConfigurationResponseValue                 = @"_value";

NSString *const kLineConfigurationResponseStatusPath            = @"login_response.status";
NSString *const kLineConfigurationResponseStatusSuccessKey          = @"_success";
NSString *const kLineConfigurationResponseStatusFailureValue        = @"false";
NSString *const kLineConfigurationResponseStatusErrorKey            = @"_error_text";

NSString *const kLineContigurationResponseDataPath              = @"branding.settings_data.core_data_list.account_list.account.data";
NSString *const kLineConfigurationResponseIdentifierKey             = @"display";
NSString *const kLineConfigurationResponseRegistrationHostKey       = @"domain";
NSString *const kLineConfigurationResponseOutboundProxyKey          = @"outboundProxy";
NSString *const kLineConfigurationResponseSipUsernameKey            = @"username";
NSString *const kLineConfigurationResponseSipPasswordKey            = @"password";
NSString *const kLineConfigurationResponseSipAccountNameKey         = @"accountName";

NSString *const kLineConfigurationInvalidServerRequestException  = @"invalidServerRequest";
NSString *const kLineConfigurationServerErrorException           = @"serverError";
NSString *const kLineConfigurationInvalidServerResponseException = @"invalidServerResponse";



@implementation LineConfiguration (Custom)

+ (void)downloadLineConfigurationForLine:(Line *)line completion:(CompletionHandler)completion
{
    NSDictionary *parameters = @{kJCLineConfigurationRequestUsernameKey:line.pbx.user.jiveUserId,
                                 kJCLineConfigurationRequestPbxIdKey:line.pbx.pbxId,
                                 kJCLineConfigurationRequestExtensionKey: line.extension};
    
    [self downloadLineConfigurationForLine:line
                                   retries:3
                                parameters:parameters
                                   success:^(id responseObject) {
                                       [self processLineConfigurationResponseObject:responseObject line:line completion:completion];
                                   }
                                   failure:^(NSError *error) {
                                       if (completion) {
                                           completion(NO, [JCClientError errorWithCode:JCClientRequestErrorCode userInfo:error.userInfo]);
                                       }
                                   }];
}

+ (void)downloadLineConfigurationForLine:(Line *)line retries:(NSInteger)retryCount parameters:(NSDictionary *)parameters success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCClientError errorWithCode:JCClientRequestErrorCode reason:@"Request Timeout"];
            failure(error);
        }
    } else {
        JCV4Client *client = [[JCV4Client alloc] init];
        client.manager.requestSerializer = [JCProvisioningXmlRequestSerializer serializer];
        [client.manager POST:kLineConfigurationRequestPath
                  parameters:parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         success(responseObject);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (error.code == NSURLErrorTimedOut) {
                             NSLog(@"Retry Line Configuration download: %lu", (long)retryCount);
                             
                             [self downloadLineConfigurationForLine:line retries:(retryCount - 1) parameters:parameters success:success failure:failure];
                         } else{
                             failure(error);
                         }
                     }];
    }
}


+ (void)processLineConfigurationResponseObject:(id)responseObject line:(Line *)line completion:(CompletionHandler)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // Check our response status. If we failed, notify and exit.
            NSDictionary *status = [responseObject valueForKeyPath:kLineConfigurationResponseStatusPath];
            NSString *success = [status stringValueForKey:kLineConfigurationResponseStatusSuccessKey];
            if ([success isEqualToString:kLineConfigurationResponseStatusFailureValue]) {
                [NSException raise:kLineConfigurationServerErrorException format:@"%@", [status stringValueForKey:kLineConfigurationResponseStatusErrorKey]];
            }
            
            // Fetch data from response. If we have no line configuration, fail.
            NSArray *array = [responseObject valueForKeyPath:kLineContigurationResponseDataPath];
            if (!array || array.count == 0) {
                [NSException raise:kLineConfigurationInvalidServerResponseException format:@"No Line Configuration present"];
            }
            
            // Process line configuration data response and store into core data, linking to our line.
            [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
                [self processLineConfigurationDataArray:array line:(Line *)[localContext objectWithID:line.objectID]];
            }
            completion:^(BOOL success, NSError *error) {
                 if (completion) {
                    if (error) {
                        completion(NO, error);
                    } else {
                        completion(YES, nil);
                    }
                 }
            }];
        }
        @catch (NSException *exception) {
            if (completion) {
                JCClientErrorCode code;
                NSString *name = exception.name;
                if ([name isEqualToString:kLineConfigurationInvalidServerRequestException]) {
                    code = JCClientInvalidRequestParameterErrorCode;
                } else if ([name isEqualToString:kLineConfigurationServerErrorException]) {
                    code = JCClientResponseErrorCode;
                } else if ([name isEqualToString:kLineConfigurationInvalidServerResponseException]) {
                    code = JCClientUnexpectedResponseErrorCode;
                } else {
                    code = JCClientUnknownErrorCode;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, [JCClientError errorWithCode:code reason:exception.reason]);
                });
            }
        }
    });
}

+ (void)processLineConfigurationDataArray:(NSArray *)array line:(Line *)line
{
    NSDictionary *data = [NSDictionary normalizeDictionaryFromArray:array keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
    if (data) {
        [LineConfiguration processLineConfigurationData:data line:line];
    } else {
        for (id object in array) {
            if ([object isKindOfClass:[NSArray class]]) {
                NSDictionary *data = [NSDictionary normalizeDictionaryFromArray:(NSArray *)object keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
                if (data) {
                    [LineConfiguration processLineConfigurationData:data line:line];
                }
            }
        }
    }
}

#pragma mark - Private -

+ (void)processLineConfigurationData:(NSDictionary *)data line:(Line *)line
{
    // If the extension for our line configuration does not match the extentsion from the requested
    // line, find the line that the line configuration does match for the same PBX, and update and
    // attach the line configuration to that line.
    NSString *extension = [LineConfiguration extensionFromLineConfigurationData:data];
    if (![extension isEqualToString:line.extension]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and extension = %@", line.pbx, extension];
        line = [Line MR_findFirstWithPredicate:predicate inContext:line.managedObjectContext];
        if (!line) {
            NSLog(@"Did not find other line for extension %@", extension);
            return;
        }
    }
    
    // If our line already has a line configuration, update it, otherwise, create a new one and
    // attach to the line.
    LineConfiguration *lineConfiguration = line.lineConfiguration;
    if (!lineConfiguration) {
        lineConfiguration = [LineConfiguration MR_createInContext:line.managedObjectContext];
        lineConfiguration.line = line;
    }
    
    // Update the line configuration from the data dictionary
    lineConfiguration.display           = [data stringValueForKey:kLineConfigurationResponseIdentifierKey];
    lineConfiguration.registrationHost  = [data stringValueForKey:kLineConfigurationResponseRegistrationHostKey];
    lineConfiguration.outboundProxy     = [data stringValueForKey:kLineConfigurationResponseOutboundProxyKey];
    lineConfiguration.sipUsername       = [data stringValueForKey:kLineConfigurationResponseSipUsernameKey];
    lineConfiguration.sipPassword       = [data stringValueForKey:kLineConfigurationResponseSipPasswordKey];
}

+ (NSString *)extensionFromLineConfigurationData:(NSDictionary *)data
{
    NSString *accountName = [data stringValueForKey:kLineConfigurationResponseSipAccountNameKey];
    if (!accountName || accountName.length == 0) {
        return nil;
    }
    
    NSArray *accountElements = [accountName componentsSeparatedByString:@":"];
    if (accountElements.count < 1) {
        return nil;
    }
    
    return [accountElements objectAtIndex:0];
}

+ (NSString *)domainFromLineConfigurationData:(NSDictionary *)data
{
    NSString *outboundProxy = [data stringValueForKey:kLineConfigurationResponseOutboundProxyKey];
    if (!outboundProxy || outboundProxy.length == 0) {
        return nil;
    }
    
    NSArray *outboundProxyElements = [outboundProxy componentsSeparatedByString:@"."];
    if (outboundProxyElements.count < 1) {
        return nil;
    }
    
    return [outboundProxyElements objectAtIndex:0];
}

@end


@implementation JCProvisioningXmlRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)object error:(NSError *__autoreleasing *)error
{
    if (![object isKindOfClass:[NSDictionary class]]) {
        *error = [JCClientError errorWithCode:JCClientInvalidRequestParameterErrorCode reason:@"Unvalid Parameters dictionary"];
        return nil;
    }
    
    NSDictionary *parameters = (NSDictionary *)object;
    NSString *username = [parameters stringValueForKey:kJCLineConfigurationRequestUsernameKey];
    if (!username) {
        *error = [JCClientError errorWithCode:JCClientInvalidRequestParameterErrorCode reason:@"Username is NULL"];
        return nil;
    }
    
    NSString *pbxId = [parameters stringValueForKey:kJCLineConfigurationRequestPbxIdKey];
    if (!pbxId) {
        *error = [JCClientError errorWithCode:JCClientInvalidRequestParameterErrorCode reason:@"PBX id is NULL"];
        return nil;
    }
        
    NSString *extension = [parameters stringValueForKey:kJCLineConfigurationRequestExtensionKey];
    if (!extension) {
        *error = [JCClientError errorWithCode:JCClientInvalidRequestParameterErrorCode reason:@"Extension is NULL"];
        return nil;
    }
    
    NSString *token = [JCAuthenticationManager sharedInstance].authToken;
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSLocale *local = [NSLocale currentLocale];
    UIDevice *device = [UIDevice currentDevice];
    
    NSString *language          = [[bundle preferredLocalizations] objectAtIndex:0];
    NSString *locale            = local.localeIdentifier;
    NSString *appBuildString    = [bundle objectForInfoDictionaryKey:(__bridge id)kCFBundleVersionKey];
    NSString *model             = device.model;
    NSString *os                = device.systemVersion;
    NSString *uuid              = [[NSString stringWithFormat:@"%@-%@", device.identifierForVendor.UUIDString, username] MD5Hash];
    NSString *type              = device.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? kJCLineConfigurationRequestDeviceTypePhone : kJCLineConfigurationRequestDeviceTypeTablet;
    
    _xml = [NSString stringWithFormat:kLineConfigurationRequestXMLString, username, token, pbxId, extension, model, os, locale, language, uuid, appBuildString, type];
    NSData *data = [_xml dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *mutableRequest = request.mutableCopy;
    [mutableRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    [mutableRequest setHTTPBody:data];
    
    mutableRequest.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    mutableRequest.HTTPShouldHandleCookies = FALSE;
    [mutableRequest setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    mutableRequest.timeoutInterval = LINE_CONFIGURATION_REQUEST_TIMEOUT;
    
    return mutableRequest;
}
@end
