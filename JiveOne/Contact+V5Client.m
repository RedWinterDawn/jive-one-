//
//  Contact+Custom.m
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Contact+V5Client.h"

// Client
#import "JCV5ApiClient.h"

// Models
#import "ContactGroup.h"
#import "PBX.h"

NSString *const kContactResponseIdentifierKey   = @"id";
NSString *const kContactResponseNameKey         = @"displayName";
NSString *const kContactResponseExtensionKey    = @"extensionNumber";
NSString *const kContactResponseJiveIdKey       = @"jiveId";
NSString *const kContactResponseGroupKey        = @"groups";
NSString *const kContactResponseGroupIdKey          = @"id";
NSString *const kContactResponseGroupNameKey        = @"name";

NSString *const kContactRequestPath = @"/contacts/2014-07/%@/line/id/%@";

@implementation Contact (V5Client)

+ (void)downloadContactsForLine:(Line *)line complete:(CompletionHandler)completion
{
    if (!line) {
        if (completion) {
            completion(false, [JCV5ApiClientError errorWithCode:JCV5ApiClientInvalidArgumentErrorCode reason:@"Line Is Null"]);
        }
        return;
    }
    
    // Request using the v5 client.
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    [client setRequestAuthHeader:YES];
    [client.manager GET:[NSString stringWithFormat:kContactRequestPath, line.pbx.pbxId, line.lineId]
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self processContactResponse:responseObject line:line completion:completion];
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    if (completion) {
                        completion(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientRequestErrorCode reason:error.localizedDescription]);
                    }
                }];
}

+ (void)processContactResponse:(id)responseObject line:(Line *)line completion:(CompletionHandler)completion
{
    @try {
        if (![responseObject isKindOfClass:[NSArray class]]){
            [NSException raise:@"v5clientException" format:@"UnexpectedResponse returned"];
        }

        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            Line *localLine = (Line *)[localContext objectWithID:line.objectID];
            [self processContactsData:(NSArray *)responseObject pbx:localLine.pbx];
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
            completion(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientResponseParseErrorCode reason:exception.reason]);
        }
    }
}

+ (void)processContactsData:(NSArray *)contactsData pbx:(PBX *)pbx
{
    NSMutableSet *contacts = pbx.contacts.mutableCopy;
    
    for (id object in contactsData)
    {
        if ([object isKindOfClass:[NSDictionary class]]) {
            Contact *contact = [self processContactData:(NSDictionary *)object pbx:pbx];
            if ([contacts containsObject:contact]) {
                [contacts removeObject:contact];
            }
        }
    }
    
    // If there are any contacts left in the array, it means we have more contacts than the server
    // response, and we need to delete the extra contacts.
    for (Contact *contact in contacts) {
        [pbx.managedObjectContext deleteObject:contact];
    }
}

+ (Contact *)processContactData:(NSDictionary *)data pbx:(PBX *)pbx
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
    
    Contact *contact = [Contact contactForJrn:jrn pbx:pbx];
    contact.name        = [data stringValueForKey:kContactResponseNameKey];
    contact.extension   = [data stringValueForKey:kContactResponseExtensionKey];
    contact.jiveUserId  = jiveUserId;
    
    id object = [data objectForKey:kContactResponseGroupKey];
    if ([object isKindOfClass:[NSArray class]]){
        [self updateContactGroupsForContact:contact data:(NSArray *)object];
    }
    return contact;
}

+(void)updateContactGroupsForContact:(Contact *)contact data:(NSArray *)data
{
    for(id object in data) {
        if ([object isKindOfClass:[NSDictionary class]]){
            NSDictionary *groupData = (NSDictionary *)object;
            NSString *identifer = [groupData stringValueForKey:kContactResponseGroupIdKey];
            ContactGroup *group = [self contactGroupForIdentifier:identifer contact:contact];
            group.name = [groupData stringValueForKey:kContactResponseGroupNameKey];
        }
    }
}

+ (Contact *)contactForJrn:(NSString *)jrn pbx:(PBX *)pbx
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and jrn = %@", pbx, jrn];
    Contact *contact = [Contact MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
    if(!contact)
    {
        contact = [Contact MR_createInContext:pbx.managedObjectContext];
        contact.jrn = jrn;
        contact.pbx = pbx;
        contact.pbxId = pbx.pbxId;
    }
    return contact;
}

+ (ContactGroup *)contactGroupForIdentifier:(NSString *)identifer contact:(Contact *)contact
{
    ContactGroup *group = [ContactGroup MR_findFirstByAttribute:NSStringFromSelector(@selector(groupId)) withValue:identifer inContext:contact.managedObjectContext];
    if (!group) {
        group = [ContactGroup MR_createInContext:contact.managedObjectContext];
        group.groupId = identifer;
    }
    
    if (![group.contacts containsObject:contact]) {
        [group addContactsObject:contact];
    }
    return group;
}

@end
