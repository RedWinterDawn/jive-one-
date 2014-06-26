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

@implementation Voicemail (Custom)


+ (NSArray *)RetrieveVoicemailById:(NSString *)conversationId
{
    NSLog(@"Voicemail+Custom.retrieveVoicemailById");
    NSArray *voicemails = [super MR_findByAttribute:@"jrn" withValue:conversationId andOrderBy:@"lastModified" ascending:YES];
    return voicemails;
}

#pragma mark - CRUD for Voicemail
+ (void)addVoicemails:(NSArray *)entryArray completed:(void (^)(BOOL))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *entry in entryArray) {
            if ([entry isKindOfClass:[NSDictionary class]]) {
                [self addVoicemail:entry withManagedContext:localContext sender:self];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
        [self fetchVoicemailInBackground];
    }];
    
}

+ (Voicemail *)addVoicemailEntry:(NSDictionary*)entry sender:(id)sender
{
    Voicemail *voicemail = [self addVoicemail:entry withManagedContext:nil sender:sender];
    if (sender != self) {
        [self fetchVoicemailInBackground];
    }
    
    return voicemail;
}

+ (Voicemail *)addVoicemail:(NSDictionary*)dictionary withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    
    Voicemail *vmail;
    //find object in core data with same urn as voicemail entry in json
    NSArray *result = [Voicemail MR_findByAttribute:@"jrn" withValue:dictionary[@"jrn"]];
    
    // if there are results, we're updating, else we're creating
    if (result.count > 0) {
        vmail = result[0];
        [self updateVoicemail:vmail withDictionary:dictionary managedContext:context];
    }
    else {
        //create and save
        vmail = [Voicemail MR_createInContext:context];


        vmail.mailboxId = dictionary[@"mailboxId"];
        vmail.timeStamp = dictionary[@"timeStamp"];
        vmail.duration = [NSNumber numberWithInteger:[dictionary[@"duration"] intValue]];
        vmail.read = [NSNumber numberWithBool:[dictionary[@"read"] boolValue]];
        vmail.transcription = dictionary[@"transcription"];
        vmail.transcriptionPercent = dictionary[@"transcriptionPercent"];
        vmail.callerId = dictionary[@"callerId"];
        vmail.jrn = dictionary[@"jrn"];
        vmail.url_self = [dictionary[@"urls"] objectForKey:@"self"];
        vmail.url_download = [dictionary[@"urls"] objectForKey:@"self_download"];
        vmail.url_changeStatus = [dictionary[@"urls"] objectForKey:@"self_changeStatus"];
        vmail.deleted = [NSNumber numberWithBool:NO];
//        //Save conversation entry
//        @try {
//            [context MR_saveToPersistentStoreAndWait];
//        }
//        @catch (NSException *exception) {
//            NSLog(@"%@", exception);
//        }
        
        
        //get all voicemail messages through a queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [(JCAppDelegate *)[UIApplication sharedApplication].delegate incrementBadgeCountForVoicemail:vmail.jrn];
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
    
    // if last modified timestamps are the same, then there's no need to update anything.
//    long long lastModifiedFromEntity = [vmail.lastModified longLongValue];
//    long long lastModifiedFromDictionary = [dictionary[@"lastModified"] longLongValue];
    
//    if (lastModifiedFromDictionary > lastModifiedFromEntity) {
    
        //update the commented fields once the model coming in the socket is the same as the model from GET
        
//        vmail.callerName = dictionary[@"callerName"];
//        vmail.callerNumber = dictionary[@"callerNumber"];
//        vmail.lastModified = [NSNumber numberWithLongLong:[dictionary[@"lastModified"] longLongValue]];
//        vmail.pbxId = dictionary[@"pbxId"];
//        vmail.lineId = dictionary[@"lineId"];
//        vmail.mailboxId = dictionary[@"mailboxId"];
//        vmail.folderId = dictionary[@"folderId"];
//        vmail.messageId = dictionary[@"messageId"];
//        vmail.extensionNumber = dictionary[@"extensionNumber"];
//        vmail.extensionName = dictionary[@"extensionName"];
//        vmail.callerId = dictionary[@"callerId"];
//        vmail.lenght = [NSNumber numberWithInteger:[dictionary[@"length"] intValue]];
//        vmail.origFile = dictionary[@"origFile"];
        if (dictionary[@"read"]) {
            vmail.read = [NSNumber numberWithBool:[dictionary[@"read"] boolValue]];
        }

        
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
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"jrn == nil"];
    
    dispatch_queue_t queue = dispatch_queue_create("load voicemails", NULL);
    dispatch_async(queue, ^{
        NSArray *voicemails = [Voicemail MR_findAllWithPredicate:pred inContext:context];
        for (Voicemail *vm in voicemails) {
            @try {
                if ([kVoicemailURLOverRide  isEqual:@"YesUseAWSPlaceholderURL"]) {
                    vm.voicemail = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://s3-us-west-2.amazonaws.com/jive-mobile/voicemail/userId/dleonard/TestVoicemail2.wav"]];
                }else{
                    if (!vm.voicemail) {
                        NSData *voiceData = [NSData dataWithContentsOfURL:[NSURL URLWithString:vm.url_download] ];
                        if (voiceData) {
                            vm.voicemail = voiceData;
                            [context MR_saveToPersistentStoreAndWait];
                        }
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
