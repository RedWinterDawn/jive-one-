//
//  LineConfiguration+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration+Custom.h"
#import "PBX.h"
#import "JCV4ProvisioningClient.h"
#import <XMLDictionary/XMLDictionary.h>

NSString *const kLineConfigurationResponseKey = @"_name";
NSString *const kLineConfigurationResponseValue = @"_value";

NSString *const kLineConfigurationResponseIdentifierKey         = @"display";
NSString *const kLineConfigurationResponseRegistrationHostKey   = @"domain";
NSString *const kLineConfigurationResponseOutboundProxyKey      = @"outboundProxy";
NSString *const kLineConfigurationResponseSipUsernameKey        = @"username";
NSString *const kLineConfigurationResponseSipPasswordKey        = @"password";
NSString *const kLineConfigurationResponseSipAccountNameKey     = @"accountName";

NSString *const kLineConfigurationInvalidServerRequestException  = @"invalidServerRequest";
NSString *const kLineConfigurationServerErrorException           = @"serverError";
NSString *const kLineConfigurationInvalidServerResponseException = @"invalidServerResponse";

@implementation LineConfiguration (Custom)

+ (void)downloadLineConfigurationForLine:(Line *)line completion:(CompletionHandler)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Line *localLine = (Line *)[[NSManagedObjectContext MR_contextForCurrentThread] objectWithID:line.objectID];
        
        @try {
            NSURLRequest *request = nil;
            request = [JCV4ProvisioningURLRequest requestWithLine:localLine];
        
            // Peform the request
            __autoreleasing NSURLResponse *response;
            __block NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (error) {
                [NSException raise:kLineConfigurationServerErrorException format:@"%@", error.description];
            }
        
            // Process Response Data
            NSDictionary *responseObject = [NSDictionary dictionaryWithXMLData:data];
            if (!response) {
                [NSException raise:kLineConfigurationInvalidServerResponseException format:@"Response Empty"];
            }
            
            NSDictionary *status = [responseObject valueForKeyPath:@"login_response.status"];
            NSString *success = [status stringValueForKey:@"_success"];
            if ([success isEqualToString:@"false"]) {
                [NSException raise:kLineConfigurationServerErrorException format:@"%@", [status stringValueForKey:@"_error_text"]];
            }
            
            NSArray *array = [responseObject valueForKeyPath:@"branding.settings_data.core_data_list.account_list.account.data"];
            if (!array || array.count == 0) {
                [NSException raise:kLineConfigurationInvalidServerResponseException format:@"No Line Configuration present"];
            }
            
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
                JCV4ProvisioningErrorType type;
                NSString *name = exception.name;
                if ([name isEqualToString:kLineConfigurationInvalidServerRequestException]) {
                    type = JCV4ProvisioningInvalidRequestParametersError;
                } else if ([name isEqualToString:kLineConfigurationServerErrorException]) {
                    type = JCV4ProvisioningRequestResponseError;
                } else if ([name isEqualToString:kLineConfigurationInvalidServerResponseException]) {
                    type = JCV4ProvisioningResponseParseError;
                } else {
                    type = JCV4ProvisioningUnknownProvisioningError;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, [JCV4ProvisioningError errorWithType:type reason:exception.reason]);
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
