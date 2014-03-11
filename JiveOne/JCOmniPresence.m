//
//  JCOmniPresence.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCOmniPresence.h"
#import "ClientEntities.h"
#import "ClientMeta.h"
#import "ContactGroup.h"
#import "Conversation+Custom.h"
#import "ConversationEntry.h"
#import "Voicemail.h"
#import "Presence.h"
#import "Company.h"

@implementation JCOmniPresence

+(instancetype)sharedInstance
{
    static JCOmniPresence *sharedObject;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[JCOmniPresence alloc] init];
    });
    
    return sharedObject;
}

- (ClientEntities*)me
{
    return [ClientEntities MR_findFirstByAttribute:@"me" withValue:[NSNumber numberWithBool:YES]];
}

- (ClientEntities*)entityByEntityId:(NSString*)entityId
{
    return [ClientEntities MR_findFirstByAttribute:@"entityId" withValue:entityId];
}

- (Presence*)presenceByEntityId:(NSString*)entityId
{
    return [Presence MR_findFirstByAttribute:@"entityId" withValue:entityId];
}

- (void)truncateAllTablesAtLogout
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    [Presence MR_truncateAllInContext:localContext];
    [ClientMeta MR_truncateAllInContext:localContext];
    [Company MR_truncateAllInContext:localContext];
    [ContactGroup MR_truncateAllInContext:localContext];
    [ConversationEntry MR_truncateAllInContext:localContext];
    [Conversation MR_truncateAllInContext:localContext];
    [Voicemail MR_truncateAllInContext:localContext];
    [ClientEntities MR_truncateAllInContext:localContext];
    [localContext MR_saveToPersistentStoreAndWait];
}

@end
