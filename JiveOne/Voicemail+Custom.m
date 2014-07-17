//
//  Voicemail+Custom.m
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail+Custom.h"
#import "VoicemailETag.h"
#import "Constants.h"
#import "JCAppDelegate.h"
#import "Common.h"

@implementation Voicemail (Custom)


+ (NSArray *)RetrieveVoicemailById:(NSString *)conversationId
{
    NSLog(@"Voicemail+Custom.retrieveVoicemailById");
    NSArray *voicemails = [super MR_findByAttribute:@"jrn" withValue:conversationId andOrderBy:@"lastModified" ascending:YES];
    return voicemails;
}

#pragma mark - CRUD for Voicemail
+ (void)addVoicemails:(NSDictionary *)responseObject mailboxUrl:(NSString *)mailboxUrl completed:(void (^)(BOOL))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *voicemail in [responseObject objectForKey:@"voicemails"]) {
            if ([voicemail isKindOfClass:[NSDictionary class]]) {
                [self addVoicemail:voicemail mailboxUrl:mailboxUrl withManagedContext:localContext sender:self];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
        [self fetchVoicemailInBackground];
    }];
    
}

+ (Voicemail *)addVoicemailEntry:(NSDictionary*)entry mailboxUrl:(NSString *)mailboxUrl sender:(id)sender
{
    Voicemail *voicemail = [self addVoicemail:entry mailboxUrl:mailboxUrl withManagedContext:nil sender:sender];
    if (sender != self) {
        [self fetchVoicemailInBackground];
    }
    
    return voicemail;
}

+ (Voicemail *)addVoicemail:(NSDictionary*)dictionary mailboxUrl:(NSString *)mailboxUrl withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    
    Voicemail *vmail;
    //find object in core data with same urn as voicemail entry in json
    NSArray *result = [Voicemail MR_findByAttribute:@"jrn" withValue:dictionary[@"jrn"] inContext:context];
    
    // if there are results, we're updating, else we're creating
    if (result.count > 0) {
        vmail = result[0];
        [self updateVoicemail:vmail withDictionary:dictionary managedContext:context];
    }
    else {
        //create and save
        vmail = [Voicemail MR_createInContext:context];

        vmail.voicemailId = dictionary[@"id"];
        //vmail.mailboxId = dictionary[@"mailboxId"];
        vmail.timeStamp = [NSNumber numberWithLongLong:[dictionary[@"timeStamp"] longLongValue]];
        vmail.duration = [NSNumber numberWithInteger:[dictionary[@"duration"] intValue]];
        vmail.read = [NSNumber numberWithBool:[dictionary[@"read"] boolValue]];
        if ([[dictionary objectForKey:@"transcription"] isKindOfClass:[NSNull class]]) {
            vmail.transcription = nil;
        } else {
            vmail.transcription = [dictionary objectForKey:@"transcription"];
        }
        if ([[dictionary objectForKey:@"transcriptionPercent"] isKindOfClass:[NSNull class]]) {
            vmail.transcriptionPercent = nil;
        } else {
            vmail.transcriptionPercent = [dictionary objectForKey:@"transcriptionPercent"];
        }
        vmail.callerId = dictionary[@"callerId"];
        if ([[dictionary objectForKey:@"callerIdNumber"] isKindOfClass:[NSNull class]]) {
            vmail.callerIdNumber = nil;
        } else {
            vmail.callerIdNumber = [dictionary objectForKey:@"callerIdNumber"];
        }

        vmail.jrn = dictionary[@"jrn"];
        __block NSString * jrn = vmail.jrn;
            
        vmail.url_self = [dictionary[@"urls"] objectForKey:@"self"];
        vmail.url_download = [dictionary[@"urls"] objectForKey:@"self_download"];
        vmail.url_changeStatus = [dictionary[@"urls"] objectForKey:@"self_changeStatus"];
        vmail.deleted = [NSNumber numberWithBool:NO];
        vmail.mailboxUrl = mailboxUrl;
        
        //get all voicemail messages through a queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [(JCAppDelegate *)[UIApplication sharedApplication].delegate incrementBadgeCountForVoicemail:jrn];
        });
        
    }
    
    if (sender != self) {
        [context MR_saveToPersistentStoreAndWait];
        return vmail;
    }
    else {
        return nil;
    }
}

+ (Voicemail *)updateVoicemail:(Voicemail*)vmail withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }

        if (dictionary[@"read"]) {
            vmail.read = [NSNumber numberWithBool:[dictionary[@"read"] boolValue]];
        }
    //TODO: things that can change
    //current folder
    //flag?
        
        //Save conversation dictionary
        @try {
            [context MR_saveToPersistentStoreAndWait];
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    
    
    return vmail;
}

+ (void)fetchVoicemailInBackground
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"voicemail == nil"];
    
    dispatch_queue_t queue = dispatch_queue_create("load voicemails", NULL);
    dispatch_async(queue, ^{
        NSArray *voicemails = [Voicemail MR_findAllWithPredicate:pred inContext:context];
        for (Voicemail *vm in voicemails) {
            @try {
                if (!vm.voicemail) {
                    NSData *voiceData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?verify=%@", vm.url_download, [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]]];
                    if (voiceData) {
                        vm.voicemail = voiceData;
                        [context MR_saveToPersistentStoreAndWait];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
            }            
        }
    });
}

+ (Voicemail *)markVoicemailForDeletion:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    Voicemail *voicemail = [Voicemail MR_findFirstByAttribute:@"jrn" withValue:voicemailId];
    
    if (voicemail) {
        voicemail.deleted = [NSNumber numberWithBool:YES];
        [context MR_saveToPersistentStoreAndWait];
        
        //save to deleted voicemail storage
        NSArray * deletedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"kDeletedVoicemail"];
        NSMutableArray *deletedList = nil;
        if (deletedArray) {
            deletedList = [NSMutableArray arrayWithArray:deletedArray];
        }
        else {
            deletedList = [NSMutableArray array];
        }
        
        [deletedList addObject:voicemailId];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:deletedList] forKey:@"kDeletedVoicemail"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return voicemail;
}

+ (BOOL)deleteVoicemail:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    //delete from Core data
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"jrn == %@", voicemailId];
    BOOL deleted = [Voicemail MR_deleteAllMatchingPredicate:pred];
    if (deleted) {
        [context MR_saveToPersistentStoreAndWait];
        
        
    }
    return deleted;
}

+ (BOOL)isVoicemailInDeletedList:(NSString*)voicemailId
{
    NSArray * deletedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"kDeletedVoicemail"];
    NSMutableArray *deletedList = nil;
    if (deletedArray) {
        deletedList = [NSMutableArray arrayWithArray:deletedArray];
        
        return [deletedList containsObject:voicemailId];
    }
    
    return NO;
}

+ (void)saveVoicemailEtag:(NSInteger)etag managedContext:(NSManagedObjectContext*)context;
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    VoicemailETag *currentETag = [VoicemailETag MR_findFirst];
    if (!currentETag) {
        currentETag = [VoicemailETag MR_createEntity];
    }
    
    //if (etag > [currentETag.etag integerValue]) {
        currentETag.etag = [NSNumber numberWithInteger:etag];
        [context MR_saveToPersistentStoreAndWait];
    //}
}

+ (NSInteger)getVoicemailEtag
{
    VoicemailETag *currentETag = [VoicemailETag MR_findFirst];
    if (currentETag) {
        return [currentETag.etag integerValue];
    }
    else {
        return 0;
    }
}


@end
