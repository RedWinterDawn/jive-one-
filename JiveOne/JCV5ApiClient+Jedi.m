//
//  JCV5ApiClient+Jedi.m
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient+Jedi.h"

#ifndef GET_JEDI_IDENTIFIER_NUMBER_OF_TRIES
#define GET_JEDI_IDENTIFIER_NUMBER_OF_TRIES 1
#endif

#ifndef UPDATE_JEDI_TOKEN_NUMBER_OF_TRIES
#define UPDATE_JEDI_TOKEN_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiJediIdentifierRequestPath = @"/jedi/v1/subscription/ios/%@";
NSString *const kJCV5ApiJediUpdatePath            = @"/jedi/v1/%@/%@";

@implementation JCV5ApiClient (Jedi)

+ (void)requestJediIdForDeviceToken:(NSString *)deviceToken completion:(JCApiClientCompletionHandler)completion
{
    if (!deviceToken) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Device Token Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiJediIdentifierRequestPath, deviceToken];
    [self postWithPath:path
            parameters:nil
     requestSerializer:[JCAuthenticationJSONRequestSerializer new]
               retries:GET_JEDI_IDENTIFIER_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)updateJediFromOldDeviceToken:(NSString *)oldDeviceToken toNewDeviceToken:(NSString *)newDeviceToken completion:(JCApiClientCompletionHandler)completion
{
    if (!oldDeviceToken) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Old Device Token Is Null"]);
        }
        return;
    }
    
    if (!newDeviceToken) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"New Device Token Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiJediUpdatePath, oldDeviceToken, newDeviceToken];
    [self putWithPath:path
           parameters:nil
    requestSerializer:[JCAuthenticationJSONRequestSerializer new]
              retries:UPDATE_JEDI_TOKEN_NUMBER_OF_TRIES
           completion:completion];
}

@end
