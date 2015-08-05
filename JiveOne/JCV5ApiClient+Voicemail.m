//
//  JCV5ApiClient+Voicemail.m
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient+Voicemail.h"

#import "Line.h"
#import "PBX.h"
#import "Voicemail.h"

#ifndef GET_VOICEMAILS_NUMBER_OF_TRIES
#define GET_VOICEMAILS_NUMBER_OF_TRIES 1
#endif

#ifndef DELETE_VOICEMAIL_NUMBER_OF_TRIES
#define DELETE_VOICEMAIL_NUMBER_OF_TRIES 1
#endif

#ifndef UPDATE_VOICEMAIL_NUMBER_OF_TRIES
#define UPDATE_VOICEMAIL_NUMBER_OF_TRIES 1
#endif

@implementation JCV5ApiClient (Voicemail)

+ (void)downloadVoicemailsForLine:(Line *)line completion:(JCApiClientCompletionHandler)completion
{
    // If the pbx is not V5, do not request for visual voicemails.
    if (!line.pbx.isV5) {
        if (completion) {
            completion(YES, nil, nil);
        }
        return;
    }
    
    // Check for required data.
    if (!line.mailboxUrl || line.mailboxUrl.isEmpty || !line.pbx) {
        if (completion != NULL) {
            completion(false, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Line has no mailbox url."]);
        }
        return;
    }
    
    [self getWithPath:line.mailboxUrl
           parameters:nil
    requestSerializer:[JCAuthenticationJSONRequestSerializer new]
              retries:GET_VOICEMAILS_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)updateVoicemail:(Voicemail *)voicemail completion:(JCApiClientCompletionHandler)completion
{
    NSString *urlString = voicemail.url_changeStatus;
    if (!urlString || urlString.length < 1) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Voicemail change status url is nil."]);
        }
        return;
    }
    
    [self putWithPath:urlString
           parameters:@{@"read": @"true"}
    requestSerializer:[JCAuthenticationJSONRequestSerializer new]
              retries:UPDATE_VOICEMAIL_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)deleteVoicemail:(Voicemail *)voicemail completion:(JCApiClientCompletionHandler)completion
{
    if(!voicemail) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Voicemail is nil."]);
        }
        return;
    }
    
    NSString *urlString = voicemail.url_self;
    if (!urlString || urlString.length < 1) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Voicemail url is nil."]);
        }
        return;
    }
    
    [self deleteWithPath:urlString
              parameters:nil
       requestSerializer:[JCAuthenticationJSONRequestSerializer new]
                 retries:DELETE_VOICEMAIL_NUMBER_OF_TRIES
              completion:completion];
}

@end
