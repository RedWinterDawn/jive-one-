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
        for (id object in dataArray) {
            if ([object isKindOfClass:[NSArray class]])
            {
                // Normalize Data into Key/value pairs.
                NSMutableDictionary *lineData = [NSMutableDictionary dictionary];
                [(NSArray *)object enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSDictionary *lineDataItem = (NSDictionary*)obj;
                    NSString *key = [lineDataItem stringValueForKey:kLineConfigurationResponseKey];
                    NSString *value = [lineDataItem stringValueForKey:kLineConfigurationResponseValue];
                    [lineData setObject:value forKey:key];
                }];
                
                
                NSString *identifier = [lineData stringValueForKey:kLineConfigurationResponseIdentifierKey];
                LineConfiguration *lineConfiguration = [LineConfiguration lineConfigurationForIdentifier:identifier context:localContext];
                
                lineConfiguration.registrationHost  = [lineData stringValueForKey:kLineConfigurationResponseRegistrationHostKey];
                lineConfiguration.outboundProxy     = [lineData stringValueForKey:kLineConfigurationResponseOutboundProxyKey];
                lineConfiguration.sipUsername       = [lineData stringValueForKey:kLineConfigurationResponseSipUsernameKey];
                lineConfiguration.sipPassword       = [lineData stringValueForKey:kLineConfigurationResponseSipPasswordKey];
            }
        }
		
	} completion:^(BOOL success, NSError *error) {
		completed(success);
	}];

}
@end
