//
//  Contact+Custom.m
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "InternalExtension+V5Client.h"

// Client
#import "JCV5ApiClient.h"

// Models
#import "InternalExtensionGroup.h"
#import "PBX.h"
#import "Line.h"
#import "User.h"

NSString *const kContactResponseIdentifierKey   = @"id";
NSString *const kContactResponseNameKey         = @"displayName";
NSString *const kContactResponseExtensionKey    = @"extensionNumber";
NSString *const kContactResponseJiveIdKey       = @"jiveId";
NSString *const kContactResponseGroupKey        = @"groups";
NSString *const kContactResponseGroupIdKey          = @"id";
NSString *const kContactResponseGroupNameKey        = @"name";

NSString *const kContactRequestPath = @"/contacts/2014-07/%@/line/id/%@";

@implementation InternalExtension (V5Client)

+ (void)downloadInternalExtensionsForLine:(Line *)line complete:(CompletionHandler)completion
{
    if (!line) {
        if (completion) {
            completion(false, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Line Is Null"]);
        }
        return;
    }
    
    // Request using the v5 client.
    JCV5ApiClient *client = [JCV5ApiClient new];
    client.manager.requestSerializer = [JCBearerAuthenticationJSONRequestSerializer serializer];
    [client.manager GET:[NSString stringWithFormat:kContactRequestPath, line.pbx.pbxId, line.lineId]
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self processInternalExtensionResponse:responseObject line:line completion:completion];
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    if (completion) {
                        completion(NO, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR reason:error.localizedDescription]);
                    }
                }];
}

+ (void)processInternalExtensionResponse:(id)responseObject line:(Line *)line completion:(CompletionHandler)completion
{
    @try {
        if (![responseObject isKindOfClass:[NSArray class]]){
            [NSException raise:@"v5clientException" format:@"UnexpectedResponse returned"];
        }

        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            Line *localLine = (Line *)[localContext objectWithID:line.objectID];
            [self processInternalExtensionsData:(NSArray *)responseObject pbx:localLine.pbx];
        } completion:^(BOOL success, NSError *error) {
            if (completion) {
                if (error) {
                    completion(NO, error);
                }
                else {
                    completion(YES, nil);
                }
            }
        }];
    }
    @catch (NSException *exception) {
        if (completion) {
            completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_PARSER_ERROR reason:exception.reason]);
        }
    }
}

+ (void)processInternalExtensionsData:(NSArray *)internalExtensionsData pbx:(PBX *)pbx
{
    
    NSMutableArray *internalExtensions = [InternalExtension MR_findByAttribute:NSStringFromSelector(@selector(pbx)) withValue:pbx inContext:pbx.managedObjectContext].mutableCopy;
    for (id object in internalExtensionsData)
    {
        if ([object isKindOfClass:[NSDictionary class]]) {
            InternalExtension *internalExtension = [self processInternalExtensionData:(NSDictionary *)object pbx:pbx];
            if ([internalExtensions containsObject:internalExtension]) {
                [internalExtensions removeObject:internalExtension];
            }
        }
    }
    
    // If there are any contacts left in the array, it means we have more contacts than the server
    // response, and we need to delete the extra contacts.
    for (InternalExtension *internalExtension in internalExtensions) {
        [pbx.managedObjectContext deleteObject:internalExtension];
    }
}

+ (InternalExtension *)processInternalExtensionData:(NSDictionary *)data pbx:(PBX *)pbx
{
    // If we do not have a jrn, we do not have its primary key, so we cannot match it to a entity,
    // so we ignore it as being a non valid response.
    NSString *jrn = [data stringValueForKey:kContactResponseIdentifierKey];
    if (!jrn) {
        return nil;
    }
    
    // If the jive user id is the same as the logged in user, do not create the contact, since it is
    // already in the Lines and will be shown in contacts.
    NSString *jiveUserId = [data stringValueForKey:kContactResponseJiveIdKey];
    if ([jiveUserId isEqualToString:pbx.user.jiveUserId]) {
        return nil;
    }
    
    InternalExtension *internalExtension = [InternalExtension internalExtensionForJrn:jrn pbx:pbx];
    internalExtension.name        = [data stringValueForKey:kContactResponseNameKey];
    internalExtension.number      = [data stringValueForKey:kContactResponseExtensionKey];
    internalExtension.jiveUserId  = jiveUserId;
    
    id object = [data objectForKey:kContactResponseGroupKey];
    if ([object isKindOfClass:[NSArray class]]){
        [self updateInternalExtensionGroupsForInternalExtension:internalExtension data:(NSArray *)object];
    }
    return internalExtension;
}

+(void)updateInternalExtensionGroupsForInternalExtension:(InternalExtension *)internalExtension data:(NSArray *)data
{
    for(id object in data) {
        if ([object isKindOfClass:[NSDictionary class]]){
            NSDictionary *groupData = (NSDictionary *)object;
            NSString *identifer = [groupData stringValueForKey:kContactResponseGroupIdKey];
            InternalExtensionGroup *group = [self internalExtensionGroupForIdentifier:identifer contact:internalExtension];
            group.name = [groupData stringValueForKey:kContactResponseGroupNameKey];
        }
    }
}

+ (InternalExtension *)internalExtensionForJrn:(NSString *)jrn pbx:(PBX *)pbx
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and jrn = %@", pbx, jrn];
    InternalExtension *internalExtension = [InternalExtension MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
    if(!internalExtension)
    {
        internalExtension = [InternalExtension MR_createEntityInContext:pbx.managedObjectContext];
        internalExtension.jrn = jrn;
        internalExtension.pbx = pbx;
        internalExtension.pbxId = pbx.pbxId;
    }
    return internalExtension;
}

+ (InternalExtensionGroup *)internalExtensionGroupForIdentifier:(NSString *)identifer contact:(InternalExtension *)contact
{
    InternalExtensionGroup *group = [InternalExtensionGroup MR_findFirstByAttribute:NSStringFromSelector(@selector(groupId)) withValue:identifer inContext:contact.managedObjectContext];
    if (!group) {
        group = [InternalExtensionGroup MR_createEntityInContext:contact.managedObjectContext];
        group.groupId = identifer;
    }
    
    if (![group.internalExtensions containsObject:contact]) {
        [group addInternalExtensionsObject:contact];
    }
    return group;
}

@end
