//
//  LineConfiguration+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration+Custom.h"
#import <XMLDictionary/XMLDictionary.h>

NSString *const kLineConfigurationResponseKey = @"_name";
NSString *const kLineConfigurationResponseValue = @"_value";

NSString *const kLineConfigurationResponseIdentifierKey         = @"display";
NSString *const kLineConfigurationResponseRegistrationHostKey   = @"domain";
NSString *const kLineConfigurationResponseOutboundProxyKey      = @"outboundProxy";
NSString *const kLineConfigurationResponseSipUsernameKey        = @"username";
NSString *const kLineConfigurationResponseSipPasswordKey        = @"password";

@implementation LineConfiguration (Custom)

+ (void)addConfiguration:(NSDictionary *)config line:(Line *)line completed:(void (^)(BOOL success, NSError *error))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        NSArray *dataArray = [config valueForKeyPath:@"branding.settings_data.core_data_list.account_list.account.data"];
        NSDictionary *data = [NSDictionary normalizeDictionaryFromArray:dataArray keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
        if (data) {
            [LineConfiguration addLineConfiguration:data line:localLine managedObjectContext:localContext];
        }
        else {
            for (id object in dataArray) {
                if ([object isKindOfClass:[NSArray class]]) {
                    NSDictionary *data = [NSDictionary normalizeDictionaryFromArray:(NSArray *)object keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
                    if (data) {
                        [LineConfiguration addLineConfiguration:data line:localLine managedObjectContext:localContext];
                    }
                }
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success, error);;
    }];
}

#pragma mark - Private -

+ (void)addLineConfiguration:(NSDictionary *)data line:(Line *)line managedObjectContext:(NSManagedObjectContext *)context
{
    LineConfiguration *lineConfiguration = line.lineConfiguration;
    if (!lineConfiguration) {
        lineConfiguration = [LineConfiguration MR_createInContext:context];
        lineConfiguration.line = line;
    }
    
    lineConfiguration.display           = [data stringValueForKey:kLineConfigurationResponseIdentifierKey];
    lineConfiguration.registrationHost  = [data stringValueForKey:kLineConfigurationResponseRegistrationHostKey];
    lineConfiguration.outboundProxy     = [data stringValueForKey:kLineConfigurationResponseOutboundProxyKey];
    lineConfiguration.sipUsername       = [data stringValueForKey:kLineConfigurationResponseSipUsernameKey];
    lineConfiguration.sipPassword       = [data stringValueForKey:kLineConfigurationResponseSipPasswordKey];
}

@end
