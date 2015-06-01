//
//  Voicemail+V5Client.m
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail+V5Client.h"

// Client
#import "JCV5ApiClient.h"
#import "JCSocket.h"

// Models
#import "PBX.h"
#import "Contact.h"
#import "Line.h"
#import "VoicemailTranscription.h"

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

NSString *const kVoicemailResponseTranscriptionKey = @"transcription";
NSString *const kVoicemailResponseTranscriptionTextKey = @"text";
NSString *const kVoicemailResponseTranscriptionConfidenceKey = @"confidence";
NSString *const kVoicemailResponseTranscriptionWordCountKey = @"wordCount";
NSString *const kVoicemailResponseTranscriptionUrlKey = @"transcription";



@implementation Voicemail (V5Client)

- (void)downloadVoicemailAudio:(CompletionHandler)completion
{
    [Voicemail downloadAudioForVoicemail:self completion:^(BOOL success, NSData *audioData, NSError *error) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            if (success) {
                Voicemail *localVoicemail = (Voicemail *)[localContext objectWithID:self.objectID];
                localVoicemail.data = audioData;
            }
        } completion:^(BOOL saveSuccess, NSError *saveError) {
            if (completion) {
                completion(success && saveSuccess, error ? error : saveError);
            }
        }];
    }];
}

-(void)markAsRead:(CompletionHandler)completion
{
    // If we are already read, we do not want to resubmit the query, so we exit.
    if (self.isRead) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    // Mark as being read and save to context. if we were sucessfull, notify the server that the
    // voicemail was listened to.
    self.read = TRUE;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            [Voicemail markVoicemailAsRead:self completion:completion];
        }
        else if (completion) {
            self.read = FALSE;
            completion(NO, error);
        }
    }];
}

-(void)markForDeletion:(CompletionHandler)completion
{
    if (self.markForDeletion) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    self.read = TRUE;
    self.markForDeletion = TRUE;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (success){
            [Voicemail deleteVoicemail:self completion:completion];
        }
        else if (completion) {
            self.read = FALSE;
            completion(NO, error);
        }
    }];
}

#pragma mark - V5 Client Requests -

+ (void)downloadVoicemailsForLine:(Line *)line completion:(CompletionHandler)completion {
    
    // If the pbx is not V5, do not request for visual voicemails.
    if (!line.pbx.isV5) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    // Check for required data.
    if (!line.mailboxUrl || line.mailboxUrl.isEmpty || !line.pbx) {
        if (completion != NULL) {
            completion(false, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Line has no mailbox url."]);
        }
        return;
    }
    
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    [client.manager GET:line.mailboxUrl
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self processVoicemailResponseObject:responseObject line:line completion:completion];
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    if (completion) {
                        completion(NO, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR reason:error.localizedDescription]);
                    }
                }];
}

+ (void)downloadAudioForVoicemail:(Voicemail *)voicemail completion:(void (^)(BOOL success, NSData *audioData, NSError *error))completion{
    
    
    if (!voicemail || !voicemail.url_download || voicemail.url_download.isEmpty) {
        if (completion != NULL) {
            completion(false, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Line has no mailbox download url."]);
        }
        return;
    }
    
    // Perform request on background thread.
    NSURL *url = [NSURL URLWithString:voicemail.url_download];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            request.URL = url;
            request.HTTPMethod = @"GET";
            [request setValue:[JCAuthenticationManager sharedInstance].authToken forHTTPHeaderField:@"Authorization"];
            
            __autoreleasing NSURLResponse *response;
            __autoreleasing NSError *error;
            NSData *voiceData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion((voiceData != nil), voiceData, [JCApiClientError errorWithCode:0 reason:@"Unable to download voicemail"]);
                });
            }
        }
    });
}

+ (void)deleteAllMarkedVoicemailsForLine:(Line *)line completion:(CompletionHandler)completion {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@ and markForDeletion == %@", line, @YES];
    NSArray *voicemails = [Voicemail MR_findAllWithPredicate:predicate inContext:line.managedObjectContext];
    if (voicemails && voicemails.count > 0) {
        for (Voicemail *voicemail in voicemails) {
            [Voicemail deleteVoicemail:voicemail completion:NULL];
        }
    }
}

+ (void)markVoicemailAsRead:(Voicemail *)voicemail completion:(CompletionHandler)completion {
    
    NSString *urlString = voicemail.url_changeStatus;
    if (!urlString || urlString.length < 1) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }
    
    JCV5ApiClient *client = [JCV5ApiClient new];
    [client.manager PUT:url.absoluteString
             parameters:@{@"read": @"true"}
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    if (completion) {
                        completion (YES, nil);
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    if (completion) {
                        completion (NO, error);
                    }
                    
                    NSString *errorMessage = @"Failed Updating Voicemail Read Status On Server, Aborting";
                    NSLog(@"%@: %@", errorMessage, [error description]);
                }];
}

+ (void)deleteVoicemail:(Voicemail *)voicemail completion:(CompletionHandler)completion
{
    if(!voicemail)
        return;
    
    NSString *urlString = voicemail.url_self;
    if (!urlString || urlString.length < 1) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }
    
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    [client.manager DELETE:url.absoluteString
                parameters:nil
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                           Voicemail *localVoicemail = (Voicemail *)[localContext objectWithID:voicemail.objectID];
                           if (localVoicemail && !localVoicemail.isDeleted) {
                               [localContext deleteObject:localVoicemail];
                           }
                       } completion:^(BOOL success, NSError *error) {
                           if (completion) {
                               completion (NO, error);
                           }
                       }];
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if (completion) {
                           completion (NO, error);
                       }
                   }];
}

+ (void)subscribeToLine:(Line *)line
{
    [JCSocket subscribeToSocketEventsWithIdentifer:line.jrn entity:line.jrn type:@"mailbox"];
}




/**
 
 private void SubscribeToVoicemail() {
 List<Line> voicemailBoxes = Line.listAll(Line.class);
 for (Line box : voicemailBoxes) {
 String jrn = box.getMailbox_jrn();
 final JasmineSubscriptionRequest request = new JasmineSubscriptionRequest();
 request.setEntity(jrn);
 request.setId();//use the empty setter. It maintains an id that we send every time so that we have a singleton subscription.
 request.setType("mailbox");
 V5Client.getInstance().subscribeToSocketEvent(subscriptionUrl, request, new ClientCallback() {
 @Override
 public void completed(boolean success, Object responseObject, Response response, RetrofitError error) {
 if (success) {
 //Log.d(ClassTag, "Subscribed to mailbox: "+  subscriptionUrl);
 }
 else{
 //didn't connect, will try again next time onOpen runs.
 //Log.d(ClassTag, "Could not subscribe to mailbox: "+  subscriptionUrl);
 Log.d(ClassTag, error.toString());
 }
 }
 });
 }
 }
 
 */

#pragma mark - Private -

#pragma mark Response Processing

+ (void)processVoicemailResponseObject:(id)responseObject line:(Line *)line completion:(CompletionHandler)completion
{
    @try {
        if (![responseObject isKindOfClass:[NSDictionary class]]){
            [NSException raise:@"v5clientException" format:@"Unexpected Voicemail response"];
        }
        
        id object = [responseObject objectForKey:@"voicemails"];
        if (![object isKindOfClass:[NSArray class]]) {
            [NSException raise:@"v5clientException" format:@"Unexpected Voicemail response array"];
        }
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            [Voicemail processVoicemailsDataArray:(NSArray *)object line:(Line *)[localContext objectWithID:line.objectID]];
        } completion:^(BOOL success, NSError *error) {
            if (completion) {
                completion((error != nil), error);
            }
        }];
    }
    @catch (NSException *exception) {
        if (completion) {
            completion(NO, [JCApiClientError errorWithCode:API_CLIENT_UNEXPECTED_RESPONSE_ERROR reason:exception.reason]);
        }
    }
}

+ (void)processVoicemailsDataArray:(NSArray *)array line:(Line *)line
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@", line];
    NSMutableArray *voicemails = [Voicemail MR_findAllWithPredicate:predicate inContext:line.managedObjectContext].mutableCopy;
    for (NSDictionary *data in array){
        if ([data isKindOfClass:[NSDictionary class]]){
            Voicemail *voicemail =  [self processVoicemailData:data line:line];
            if (voicemail && [voicemails containsObject:voicemail]) {
                [voicemails removeObject:voicemail];
            }
        }
    }
    
    // If there are any voicemails left in the array, it means we have more contacts than the server
    // response, and we need to delete the extra voicemails.
    for (Voicemail *voicemail in voicemails) {
        [line.managedObjectContext deleteObject:voicemail];
    }
}

+ (Voicemail *)processVoicemailData:(NSDictionary *)data line:(Line *)line
{
    // Require that we have a jrn. If we no not have one, we can not create a voicemail, so exit returning nil.
    NSString *identifier = [data stringValueForKey:kVoicemailResponseIdentifierKey];
    if (!identifier) {
        return nil;
    }
    
    // Fetches the voicemail to update it. If it did not yet exist, it is created with the JRN being the identifier.
    Voicemail *voicemail = [Voicemail voicemailForIdentifier:identifier line:line];
    voicemail.duration          = [data integerValueForKey:kVoicemailResponseDurationKey];
    voicemail.read              = [data boolValueForKey:kVoicemailResponseReadKey];
    voicemail.name              = [data stringValueForKey:kVoicemailResponseNameKey];
    voicemail.number            = [data stringValueForKey:kVoicemailResponseNumberKey];
    voicemail.url_self          = [data stringValueForKey:kVoicemailResponseSelfKey];
    voicemail.url_download      = [data stringValueForKey:kVoicemailResponseSelfDownloadKey];
    voicemail.url_changeStatus  = [data stringValueForKey:kVoicemailResponseSelfChangeStatusKey];
    voicemail.mailboxUrl        = [data stringValueForKey:kVoicemailResponseSelfMailboxKey];
    voicemail.unixTimestamp     = [data integerValueForKey:kVoicemailResponseTimestampKey];
    Extension *extension = [Extension extensionForNumber:voicemail.number onPbx:line.pbx excludingLine:line];
    if ([extension isKindOfClass:[Contact class]]) {
        voicemail.contact = (Contact *)extension;
    }
    
    NSDictionary *transcriptionData = [data dictionaryForKey:kVoicemailResponseTranscriptionKey];
    if (transcriptionData) {
        [self processVoicemailTranscriptionData:transcriptionData voicemail:voicemail];
    }
    
    
    if (!voicemail.data) {
        [voicemail downloadVoicemailAudio:NULL];
    }
    return voicemail;
}

+(void)processVoicemailTranscriptionData:(NSDictionary *)data voicemail:(Voicemail *)voicemail
{
    NSString *text = [data stringValueForKey:kVoicemailResponseTranscriptionTextKey];
    if (!text) {
        return;
    }
    
    VoicemailTranscription *transcription = voicemail.transcription;
    if (!transcription) {
        transcription = [VoicemailTranscription MR_createEntityInContext:voicemail.managedObjectContext];
        transcription.voicemail = voicemail;
    }
    transcription.text = text;
    transcription.wordCount = [data integerValueForKey:kVoicemailResponseTranscriptionWordCountKey];
    transcription.confidence = [data floatValueForKey:kVoicemailResponseTranscriptionConfidenceKey];
    transcription.url_self = [data stringValueForKey:kVoicemailResponseTranscriptionUrlKey];
    
}

+ (Voicemail *)voicemailForIdentifier:(NSString *)identifier line:(Line *)line
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"line = %@ and jrn = %@", line, identifier];
    Voicemail *voicemail = [Voicemail MR_findFirstWithPredicate:predicate inContext:line.managedObjectContext];
    if (!voicemail) {
        voicemail = [Voicemail MR_createEntityInContext:line.managedObjectContext];
        voicemail.jrn = identifier;
        voicemail.line = line;
    }
    return voicemail;
}

@end
