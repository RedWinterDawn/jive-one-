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

#import "JCVoicemailClient.h"

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
        vmail.unixTimestamp = [dictionary[@"timeStamp"] longLongValue];
        vmail.duration = [NSNumber numberWithInteger:[dictionary[@"duration"] intValue]];
        vmail.read = [dictionary[@"read"] boolValue];
        /*if ([[dictionary objectForKey:@"transcription"] isKindOfClass:[NSNull class]]) {
            vmail.transcription = nil;
        } else {
            vmail.transcription = [dictionary objectForKey:@"transcription"];
        }
        if ([[dictionary objectForKey:@"transcriptionPercent"] isKindOfClass:[NSNull class]]) {
            vmail.transcriptionPercent = nil;
        } else {
            vmail.transcriptionPercent = [dictionary objectForKey:@"transcriptionPercent"];
        }*/
        vmail.name = dictionary[@"callerId"];
        if ([[dictionary objectForKey:@"callerIdNumber"] isKindOfClass:[NSNull class]]) {
            vmail.number = nil;
        } else {
            vmail.number = [dictionary objectForKey:@"callerIdNumber"];
        }

        vmail.jrn = dictionary[@"jrn"];
        vmail.url_self = dictionary[@"self"];
	    vmail.url_download = dictionary[@"self_download"];
		vmail.url_changeStatus = dictionary[@"self_changeStatus"] ;
        vmail.markForDeletion = [NSNumber numberWithBool:NO];
        vmail.mailboxUrl = mailboxUrl;
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


        if (dictionary[@"read"]) {
            vmail.read = [dictionary[@"read"] boolValue];
        }
    //TODO: things that can change
    //current folder
    //flag?
        
        //Save conversation dictionary
//        @try {
//            [context MR_saveToPersistentStoreAndWait];
//        }
//        @catch (NSException *exception) {
//            NSLog(@"%@", exception);
//        }
    
    
    return vmail;
}

+ (void)fetchVoicemailsInBackground:(void(^)(BOOL success, NSError *error))completed
{
    // V5 only provides voicemail through REST. So re make a REST Call
    [[JCVoicemailClient sharedClient] getVoicemails:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if (completed != nil) {
            if (suceeded && completed != NULL) {
                completed(true, nil);
            }
            else {
                completed(false, error);
            }
        }
    }];
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
					
					NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
					request.URL = [NSURL URLWithString:vm.url_download];
					request.HTTPMethod = @"GET";
					[request setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"] forHTTPHeaderField:@"Authorization"];
					
					NSURLResponse *response;
					NSError *error;
					
					NSData *voiceData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
					
                    //NSData *voiceData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?verify=%@", vm.url_download, ]]];
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

+ (void)deleteVoicemailsInBackground
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion ==[c] %@", [NSNumber numberWithBool:YES]];
    NSArray *deletedVoicemails = [NSMutableArray arrayWithArray:[Voicemail MR_findAllWithPredicate:predicate]];
    
    if (deletedVoicemails.count > 0) {
        for (Voicemail *voice in deletedVoicemails) {
            if(voice.url_self){
                [[JCVoicemailClient sharedClient] deleteVoicemail:voice.url_self completed:^(BOOL succeeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
                    if (succeeded) {
                        [Voicemail deleteVoicemail:voice.jrn managedContext:nil];
                    }
                    else {
                        NSLog(@"Error Deleting Voicemail: %@", error);
                    }
                }];
            }
            else{
                [Flurry logError:@"Voicemail Service" message:@"url_self is nil to delete" error:nil];
            }
        }
    }
}

+ (Voicemail *)markVoicemailForDeletion:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    Voicemail *voicemail = [Voicemail MR_findFirstByAttribute:@"jrn" withValue:voicemailId];
    
    if (voicemail) {
        voicemail.markForDeletion = [NSNumber numberWithBool:YES];
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



-(void)markAsRead
{
    if (self.read) {
        return;
    }
    
    self.read = TRUE;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (success)
        {
            // now send update to server
            [[JCVoicemailClient sharedClient] updateVoicemailToRead:self completed:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
                if(error)
                {
                    NSString *errorMessage = @"Failed Updating Voicemail Read Status On Server, Aborting";
                    NSLog(@"%@", errorMessage);
                    [Flurry logError:@"Voicmail-11" message:errorMessage error:error];
                }
            }];
        }
    }];
}


@end
