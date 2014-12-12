//
//  Contact+Custom.m
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Contact+Custom.h"
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

+ (Contact *)updateContact:(NSDictionary *)data pbx:(PBX *)pbx
{
    NSString *jrn = [data stringValueForKey:kContactResponseIdentifierKey];
    if (!jrn) {
        return nil;
    }
    
    Contact *contact = [Contact contactForJrn:jrn pbx:pbx];
    contact.name        = [data stringValueForKey:kContactResponseNameKey];
    //line.extension   = [data stringValueForKey:kLineResponseLineNumberKey];
    //line.mailboxUrl  = [data stringValueForKey:kLineResponseMailboxUrlKey];
    //line.mailboxJrn  = [data stringValueForKey:kLineResponseMailboxJrnKey];
    //line.state       = [NSNumber numberWithInt:(int)JCPresenceTypeAvailable];
    
    return contact;
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


@end
