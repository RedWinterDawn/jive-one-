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

#import "NSDictionary+Validations.h"

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

NSString *const kVoicemailResponseIdentifierKey         = @"jrn";
NSString *const kVoicemailResponseDurationKey           = @"duration";
NSString *const kVoicemailResponseReadKey               = @"read";
NSString *const kVoicemailResponseNameKey               = @"callerId";
NSString *const kVoicemailResponseNumberKey             = @"callerIdNumber";
NSString *const kVoicemailResponseTimestampKey          = @"timeStamp";
NSString *const kVoicemailResponseSelfKey               = @"self";
NSString *const kVoicemailResponseSelfDownloadKey       = @"self_download";
NSString *const kVoicemailResponseSelfChangeStatusKey   = @"self_changeStatus";
NSString *const kVoicemailResponseSelfMailboxKey        = @"self_mailbox";



+ (Voicemail *)addVoicemail:(NSDictionary*)dictionary mailboxUrl:(NSString *)mailboxUrl withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    // Require that we have a jrn. If we no not have one, we can not create a voicemail, so exit returning nil.
    NSString *identifier = [dictionary stringValueForKey:kVoicemailResponseIdentifierKey];
    if (!identifier) {
        return nil;
    }
    
    // Fetches the voicemail to update it. If it did not yet exist, it is created with the JRN being the identifier.
    Voicemail *voicemail = [Voicemail voicemailForIdentifier:identifier context:context];
    
    voicemail.duration          = [dictionary integerValueForKey:kVoicemailResponseDurationKey];
    voicemail.read              = [dictionary boolValueForKey:kVoicemailResponseReadKey];
    voicemail.name              = [dictionary stringValueForKey:kVoicemailResponseNameKey];
    voicemail.number            = [dictionary stringValueForKey:kVoicemailResponseNumberKey];
    voicemail.url_self          = [dictionary stringValueForKey:kVoicemailResponseSelfKey];
    voicemail.url_download      = [dictionary stringValueForKey:kVoicemailResponseSelfDownloadKey];
    voicemail.url_changeStatus  = [dictionary stringValueForKey:kVoicemailResponseSelfChangeStatusKey];
    voicemail.mailboxUrl        = [dictionary stringValueForKey:kVoicemailResponseSelfMailboxKey];
    
    NSInteger timestamp         = [dictionary integerValueForKey:kVoicemailResponseTimestampKey];
    voicemail.unixTimestamp = timestamp;
    
    if (sender != self) {
        [voicemail.managedObjectContext MR_saveToPersistentStoreAndWait];
        return voicemail;
    }
    else {
        return nil;
    }
}

+ (Voicemail *)voicemailForIdentifier:(NSString *)identifier context:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    Voicemail *voicemail = [Voicemail MR_findFirstByAttribute:@"jrn" withValue:identifier inContext:context];
    if (!voicemail) {
        voicemail = [Voicemail MR_createInContext:context];
        voicemail.jrn = identifier;
    }
    return voicemail;
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
        voicemail.markForDeletion = YES;
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
