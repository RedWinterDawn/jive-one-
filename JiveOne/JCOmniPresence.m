//
//  JCOmniPresence.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCOmniPresence.h"
#import "PersonEntities.h"
#import "PersonMeta.h"
#import "ContactGroup.h"
#import "Conversation+Custom.h"
#import "ConversationEntry.h"
#import "Voicemail.h"
#import "Presence.h"
#import "Company.h"
#import "Membership+Custom.h"
#import "PBX+Custom.h"
#import "LineGroup.h"
#import "Lines.h"
#import "LineConfiguration.h"
#import "Call.h"


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

- (PersonEntities*)me
{
    return [PersonEntities MR_findFirstByAttribute:@"me" withValue:[NSNumber numberWithBool:YES]];
}

- (PersonEntities*)entityByEntityId:(NSString*)entityId
{
    return [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:entityId];
}

- (Presence*)presenceByEntityId:(NSString*)entityId
{
    return [Presence MR_findFirstByAttribute:@"entityId" withValue:entityId];
}

- (void)truncateAllTablesAtLogout
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    [Presence MR_truncateAllInContext:localContext];
    [PersonMeta MR_truncateAllInContext:localContext];
    [Company MR_truncateAllInContext:localContext];
    [ContactGroup MR_truncateAllInContext:localContext];
    [ConversationEntry MR_truncateAllInContext:localContext];
    [Conversation MR_truncateAllInContext:localContext];
    [Voicemail MR_truncateAllInContext:localContext];
    [PersonEntities MR_truncateAllInContext:localContext];
	[Voicemail MR_truncateAllInContext:localContext];
	[Membership MR_truncateAllInContext:localContext];
	[PBX MR_truncateAllInContext:localContext];
	[LineGroup MR_truncateAllInContext:localContext];
	[Lines MR_truncateAllInContext:localContext];
	[LineConfiguration MR_truncateAllInContext:localContext];
    [Call MR_truncateAllInContext:localContext];
	
    [localContext MR_saveToPersistentStoreAndWait];
}

@end
