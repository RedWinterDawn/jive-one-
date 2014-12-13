//
//  Contact+Custom.m
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Contact+Custom.h"
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

@implementation Contact (Custom)

+ (void)downloadContactsForLine:(Line *)line complete:(CompletionHandler)complete
{
    if (!line) {
        if (complete != NULL) {
            complete(false, [JCV5ApiClientError errorWithCode:JCV5ApiClientInvalidArgumentErrorCode reason:@"Line Is Null"]);
        }
        return;
    }
    
    NSString *url = [NSString stringWithFormat:kContactRequestPath, line.pbx.pbxId, line.lineId];
    
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    [client setRequestAuthHeader:YES];
    [client.manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSArray class]]){
            NSArray *array = (NSArray *)responseObject;
            if (array && array.count > 0)
            {
                [Contact updateContacts:array pbx:line.pbx complete:^(BOOL success, NSError *error) {
                    if (complete) {
                        complete(success, error);
                    }
                }];
            }
        } else {
            complete(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientResponseParseErrorCode reason:@"Unexpected response returned"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (complete) {
            complete(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientRequestErrorCode reason:error.localizedDescription]);
        }
        
    }];
}

+ (void)updateContacts:(NSArray *)contactsData pbx:(PBX *)pbx complete:(CompletionHandler)complete
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (id object in contactsData)
        {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [self updateContact:(NSDictionary *)object pbx:(PBX *)[localContext objectWithID:pbx.objectID]];
            }
            else {
                complete(false, nil);
            }
        }
    } completion:^(BOOL success, NSError *error) {
        complete(success, error);
    }];
}

+ (void)updateContact:(NSDictionary *)data pbx:(PBX *)pbx
{
    // If we do not have a jrn, we do not have its primary key, so we cannot match it to a entity,
    // so we ignore it as being a non valid response.
    NSString *jrn = [data stringValueForKey:kContactResponseIdentifierKey];
    if (!jrn) {
        return;
    }
    
    // If the jive user id is the same as the logged in user, do not create the contact, since it is
    // already in the Lines and will be shown in contacts.
    NSString *jiveUserId = [data stringValueForKey:kContactResponseJiveIdKey];
    if ([jiveUserId isEqualToString:pbx.user.jiveUserId]) {
        return;
    }
    
    Contact *contact = [Contact contactForJrn:jrn pbx:pbx];
    contact.name        = [data stringValueForKey:kContactResponseNameKey];
    contact.extension   = [data stringValueForKey:kContactResponseExtensionKey];
    contact.jiveUserId  = jiveUserId;
    
    id object = [data objectForKey:kContactResponseGroupKey];
    if ([object isKindOfClass:[NSArray class]]){
        [Contact updateContactGroupsForContact:contact data:(NSArray *)object];
    }
    return;
}

+(void)updateContactGroupsForContact:(Contact *)contact data:(NSArray *)data
{
    for(id object in data) {
        if ([object isKindOfClass:[NSDictionary class]]){
            NSDictionary *groupData = (NSDictionary *)object;
            NSString *identifer = [groupData stringValueForKey:kContactResponseGroupIdKey];
            ContactGroup *group = [Contact contactGroupForIdentifier:identifer contact:contact];
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
    }
    return contact;
}

+ (ContactGroup *)contactGroupForIdentifier:(NSString *)identifer contact:(Contact *)contact
{
    ContactGroup *group = [ContactGroup MR_findFirstByAttribute:@"groupId" withValue:identifer inContext:contact.managedObjectContext];
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
