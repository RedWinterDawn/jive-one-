//
//  JCV5ApiClient+Jif.m
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient+Jif.h"

#import "User.h"

#ifndef PBX_INFO_NUMBER_OF_TRIES
#define PBX_INFO_SEND_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiPBXInfoRequestPath = @"/jif/v3/user/jiveId/%@";

@implementation JCV5ApiClient (Jif)

+ (void)requestPBXInforForUser:(User *)user competion:(JCApiClientCompletionHandler)completion
{
    if (!user) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"User Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiPBXInfoRequestPath, user.jiveUserId];
    [self getWithPath:path
           parameters:nil
    requestSerializer:nil
              retries:PBX_INFO_SEND_NUMBER_OF_TRIES
           completion:completion];
}

@end
