//
//  LineConfiguration+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration+Custom.h"
#import <XMLDictionary/XMLDictionary.h>

#import "NSDictionary+Validations.h"

NSString *const kLineConfigurationResponseKey = @"_name";
NSString *const kLineConfigurationResponseValue = @"_value";

NSString *const kLineConfigurationResponseIdentifierKey         = @"display";
NSString *const kLineConfigurationResponseRegistrationHostKey   = @"domain";
NSString *const kLineConfigurationResponseOutboundProxyKey      = @"outboundProxy";
NSString *const kLineConfigurationResponseSipUsernameKey        = @"username";
NSString *const kLineConfigurationResponseSipPasswordKey        = @"password";

@implementation LineConfiguration (Custom)

+(LineConfiguration *)lineConfigurationForIdentifier:(NSString *)identifier context:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    LineConfiguration *lineConfiguration = [LineConfiguration MR_findFirstByAttribute:@"display" withValue:identifier inContext:context];
    if (!lineConfiguration) {
        lineConfiguration = [LineConfiguration MR_createInContext:context];
        lineConfiguration.display = identifier;
    }
    
    return lineConfiguration;
}

+ (void)addConfiguration:(NSDictionary *)config completed:(void (^)(BOOL success))completed
{
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		
		NSArray *dataArray = [config valueForKeyPath:@"branding.settings_data.core_data_list.account_list.account.data"];
        NSDictionary *data = [LineConfiguration normalizeDictionaryFromArray:dataArray keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
        if (data) {
            [LineConfiguration addLineConfiguration:data managedObjectContext:localContext];
        }
        else
        {
            for (id object in dataArray) {
                if ([object isKindOfClass:[NSArray class]])
                {
                    NSDictionary *data = [LineConfiguration normalizeDictionaryFromArray:(NSArray *)object keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
                    if (data) {
                        [LineConfiguration addLineConfiguration:data managedObjectContext:localContext];
                    }
                }
            }
        }
		
	} completion:^(BOOL success, NSError *error) {
		completed(success);
	}];

}

+ (NSDictionary *)normalizeDictionaryFromArray:(NSArray *)array keyIdentifier:(NSString *)keyIdentifier valueIdentifier:(NSString *)valueIdentifier
{
    // Normalize Data into Key/value pairs.
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *item = (NSDictionary*)obj;
            NSString *key = [item stringValueForKey:keyIdentifier];
            NSString *value = [item stringValueForKey:valueIdentifier];
            [dictionary setObject:value forKey:key];
        }
    }];
    
    return (dictionary.count > 0) ? dictionary : nil;
}

+ (void)addLineConfiguration:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)context
{
    NSString *identifier = [data stringValueForKey:kLineConfigurationResponseIdentifierKey];
    LineConfiguration *lineConfiguration = [LineConfiguration lineConfigurationForIdentifier:identifier context:context];
    
    lineConfiguration.registrationHost  = [data stringValueForKey:kLineConfigurationResponseRegistrationHostKey];
    lineConfiguration.outboundProxy     = [data stringValueForKey:kLineConfigurationResponseOutboundProxyKey];
    lineConfiguration.sipUsername       = [data stringValueForKey:kLineConfigurationResponseSipUsernameKey];
    lineConfiguration.sipPassword       = [data stringValueForKey:kLineConfigurationResponseSipPasswordKey];
}

@end
