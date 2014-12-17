//
//  LineConfiguration+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration+Custom.h"
#import "PBX.h"

NSString *const kLineConfigurationResponseKey = @"_name";
NSString *const kLineConfigurationResponseValue = @"_value";

NSString *const kLineConfigurationResponseIdentifierKey         = @"display";
NSString *const kLineConfigurationResponseRegistrationHostKey   = @"domain";
NSString *const kLineConfigurationResponseOutboundProxyKey      = @"outboundProxy";
NSString *const kLineConfigurationResponseSipUsernameKey        = @"username";
NSString *const kLineConfigurationResponseSipPasswordKey        = @"password";
NSString *const kLineConfigurationResponseSipAccountNameKey     = @"accountName";

@implementation LineConfiguration (Custom)

+ (void)addLineConfigurations:(NSArray *)array line:(Line *)line completed:(void (^)(BOOL success, NSError *error))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        NSDictionary *data = [NSDictionary normalizeDictionaryFromArray:array keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
        if (data) {
            [LineConfiguration updateLineConfigurationWithData:data line:localLine];
        }
        else {
            for (id object in array) {
                if ([object isKindOfClass:[NSArray class]]) {
                    NSDictionary *data = [NSDictionary normalizeDictionaryFromArray:(NSArray *)object keyIdentifier:kLineConfigurationResponseKey valueIdentifier:kLineConfigurationResponseValue];
                    if (data) {
                        [LineConfiguration updateLineConfigurationWithData:data line:localLine];
                    }
                }
            }
        }
    } completion:^(BOOL success, NSError *error) {
        if (completed) {
            completed(success, error);
        }
    }];
}

#pragma mark - Private -

+ (void)updateLineConfigurationWithData:(NSDictionary *)data line:(Line *)line
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
