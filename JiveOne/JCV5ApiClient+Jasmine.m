//
//  JCV5ApiClient+Jasmine.m
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient+Jasmine.h"

#ifndef GET_JASMINE_PRIORITY_SESSION_NUMBER_OF_TRIES
#define GET_JASMINE_PRIORITY_SESSION_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ClientSocketBaseURL           = @"https://realtime.jive.com";
NSString *const kJCV5ClientSocketSessionRequestURL = @"/v2/session/priority/jediId/%@";

@implementation JCV5ApiClient (Jasmine)

+ (void)requestPrioritySessionForJediId:(NSString *)jediId completion:(JCApiClientCompletionHandler)completion
{
    if (!jediId) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Jedi ID Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ClientSocketSessionRequestURL, jediId];
    JCV5ApiClient *client = [[JCV5ApiClient alloc] initWithBaseURL:[NSURL URLWithString:kJCV5ClientSocketBaseURL]];
    [client requestWithType:JCApiClientPost
                       path:path
                 parameters:nil
          requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
         responceSerializer:nil
                    retries:GET_JASMINE_PRIORITY_SESSION_NUMBER_OF_TRIES
                    success:^(id responseObject) {
                        if (completion) {
                            completion(YES, responseObject, nil);
                        }
                    }
                    failure:^(id responseObject, NSError *error) {
                        if (completion) {
                            completion(NO, responseObject, error);
                        }
                    }];
}

@end
