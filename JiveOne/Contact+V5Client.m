//
//  Contact+V5Client.m
//  JiveOne
//
//  Created by Robert Barclay on 6/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Contact+V5Client.h"

// Client
#import "JCV5ApiClient.h"

// Models
#import "User.h"
#import "Contact.h"

@implementation Contact (V5Client)

+ (void)downloadContactsForUser:(User *)user completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadContactsWithCompletion:^(BOOL success, id response, NSError *error) {
        if (success) {
            [self processContactsDownloadResponse:response user:user completion:completion];
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

+ (void)downloadContact:(Contact *)contact completion:(CompletionHandler)completion
{
    
}

+ (void)uploadContact:(Contact *)contact completion:(CompletionHandler)completion
{
    [JCV5ApiClient uploadContact:contact completion:^(BOOL success, id response, NSError *error) {
        if (success) {
            [self processContactUploadResponse:response contact:contact completion:completion];
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

+ (void)deleteContact:(Contact *)contact completion:(CompletionHandler)completion
{
    
}

#pragma mark - Private -

+ (void)processContactsDownloadResponse:(id)responseObject user:(User *)user completion:(CompletionHandler)completion
{
    @try {
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid contacts response. Expecting an Array"];
        }
        
        NSArray *contactsData = (NSArray *)responseObject;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            [self processContactsArrayData:contactsData user:(User *)[localContext objectWithID:user.objectID]];
        } completion:^(BOOL contextDidSave, NSError *error) {
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
            completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:exception.reason]);
        }
    }
}

+ (void)processContactsArrayData:(NSArray *)contactsData user:(User *)user
{
    
}

#pragma mark Upload

+ (void)processContactUploadResponse:(id)responseObject contact:(Contact *)contact completion:(CompletionHandler)completion
{
    @try {
        
        NSDictionary *contactData = nil;
        
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            [self processContactUpload:contactData contact:(Contact *)[localContext objectWithID:contact.objectID]];
        } completion:^(BOOL contextDidSave, NSError *error) {
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
            completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:exception.reason]);
        }
    }
}

+ (void)processContactUpload:(NSDictionary *)contactData contact:(Contact *)contact
{
    
}

@end
