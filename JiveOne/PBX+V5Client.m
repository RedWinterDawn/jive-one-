 //
//  PBX+V5Client.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX+V5Client.h"

// V5 Client
#import "JCV5ApiClient.h"

// Managed Objects
#import "Line.h"
#import "User.h"


NSString *const kPBXInfoRequestPath             = @"/jif/v1/user/jiveId/%@?depth=1";
NSString *const kPBXInfoRequestResultKey        = @"userPbxs";

NSString *const kPBXResponseIdentifierKey       = @"pbxId";
NSString *const kPBXResponseNameKey             = @"name";
NSString *const kPBXResponseV5Key               = @"v5";
NSString *const kPBXResponseLinesKey            = @"lines";
NSString *const kPBXLineResponseIdentifierKey       = @"id";
NSString *const kPBXLineResponseLineNameKey         = @"lineName";
NSString *const kPBXLineResponseLineNumberKey       = @"lineNumber";
NSString *const kPBXLineResponseJrnKey              = @"jrn";
NSString *const kPBXLineResponseMailboxUrlKey       = @"self_mailbox";
NSString *const kPBXLineResponseMailboxJrnKey       = @"mailbox_jrn";

NSString *const kPBXResponseException           = @"pbxResponseException";

@implementation PBX (V5Client)

+ (void)downloadPbxInfoForUser:(User *)user completed:(void(^)(BOOL success, NSError *error))completion
{
    if (!user) {
        if (completion != NULL) {
            completion(false, [JCV5ApiClientError errorWithCode:JCV5ApiClientInvalidArgumentErrorCode reason:@"User Is Null"]);
        }
        return;
    }
    
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    [client setRequestAuthHeader:NO];
    [client.manager GET:[NSString stringWithFormat:kPBXInfoRequestPath, user.jiveUserId]
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self processRequestResponse:responseObject user:user competion:completion];
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    completion(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientRequestErrorCode reason:error.localizedDescription]);
                }];
}

+(void)processRequestResponse:(id)responseObject user:(User *)user competion:(CompletionHandler)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        User *localUser = (User *)[[NSManagedObjectContext MR_contextForCurrentThread] objectWithID:user.objectID];
        @try {
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                [NSException raise:kPBXResponseException format:@"Invalid pbxs response object."];
            }
            
            NSArray *pbxsData = [(NSDictionary *)responseObject arrayForKey:kPBXInfoRequestResultKey];
            if (!pbxsData) {
                [NSException raise:kPBXResponseException format:@"Invalid pbx response array."];
            }
            
            // Process response array to add, update or remove pbxs
            [self processPbxArrayData:pbxsData user:localUser];
            
            // If the context has changed, save it.
            __autoreleasing NSError *error;
            NSManagedObjectContext *context = localUser.managedObjectContext;
            if (context.hasChanges) {
                [context save:&error];
            }
            
            __block NSError *blockError = error;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (blockError) {
                    completion(NO, blockError);
                }
                else {
                    completion(YES, nil);
                }
            });
        }
        @catch (NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientResponseParseErrorCode reason:exception.reason]);
            });
        }
    });
}

/**
 * Recieves an array of PBXs and iterates over them, saving them to core data. Exiting pbx that are 
 * not in the update array, are removed.
 */
+ (void)processPbxArrayData:(NSArray *)pbxsData user:(User *)user
{
    // Grab the Users pbxs before we start adding new ones or updating exiting ones.
    NSMutableSet *pbxs = user.pbxs.mutableCopy;
    
    for (NSDictionary *pbxData in pbxsData) {
        if ([pbxData isKindOfClass:[NSDictionary class]]) {
            PBX *pbx = [self processPbxData:pbxData forUser:user];
            if ([pbxs containsObject:pbx]) {
                [pbxs removeObject:pbx];
            }
        }
    }
    
    // If there are any pbxs left in the array, it means we have more pbxs than the server response,
    // and we need to delete the extra pbxs.
    if (pbxs.count > 0) {
        for (PBX *pbx in pbxs) {
            [user.managedObjectContext deleteObject:pbx];
        }
    }
}

+ (PBX *)processPbxData:(NSDictionary *)data forUser:(User *)user
{
    NSString *pbxId = [data stringValueForKey:kPBXResponseIdentifierKey];
    if (!pbxId) {
        return nil;
    }
    
    PBX *pbx = [PBX pbxForPbxId:pbxId user:user];
    pbx.name = [data stringValueForKey:kPBXResponseNameKey];
    pbx.v5   = [data boolValueForKey:kPBXResponseV5Key];
    
    NSArray *lines = [data arrayForKey:kPBXResponseLinesKey];
    if (lines.count > 0) {
        [self processLines:lines pbx:pbx];
    }
    return pbx;
}

+ (PBX *)pbxForPbxId:(NSString *)pbxId user:(User *)user
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@ and pbxId = %@", user, pbxId];
    PBX *pbx = [PBX MR_findFirstWithPredicate:predicate inContext:user.managedObjectContext];
    if (!pbx) {
        pbx = [PBX MR_createInContext:user.managedObjectContext];
        pbx.pbxId = pbxId;
        pbx.user = user;
    }
    return pbx;
}

#pragma mark - Lines Info -

+ (void)processLines:(NSArray *)linesData pbx:(PBX *)pbx
{
    NSMutableSet *lines = pbx.lines.mutableCopy;
    
    for (id object in linesData){
        if ([object isKindOfClass:[NSDictionary class]]) {
            Line *line = [self processLine:(NSDictionary *)object pbx:pbx];
            if ([lines containsObject:line]) {
                [lines removeObject:line];
            }
        }
    }
    
    // If there are any pbxs left in the array, it means we have more pbxs than the server response,
    // and we need to delete the extra pbxs.
    if (lines.count > 0) {
        for (Line *line in lines) {
            [pbx.managedObjectContext deleteObject:line];
        }
    }
}

+ (Line *)processLine:(NSDictionary *)data pbx:(PBX *)pbx
{
    NSString *jrn = [data stringValueForKey:kPBXLineResponseJrnKey];
    if (!jrn) {
        return nil;
    }
    
    Line *line = [self lineForJrn:jrn pbx:pbx];
    line.name        = [data stringValueForKey:kPBXLineResponseLineNameKey];
    line.extension   = [data stringValueForKey:kPBXLineResponseLineNumberKey];
    line.mailboxUrl  = [data stringValueForKey:kPBXLineResponseMailboxUrlKey];
    line.mailboxJrn  = [data stringValueForKey:kPBXLineResponseMailboxJrnKey];
    return line;
}

+ (Line *)lineForJrn:(NSString *)jrn pbx:(PBX *)pbx
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and jrn = %@", pbx, jrn];
    Line *line = [Line MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
    if(!line) {
        line = [Line MR_createInContext:pbx.managedObjectContext];
        line.jrn = jrn;
        line.pbx = pbx;
        line.pbxId = pbx.pbxId;
    }
    return line;
}

@end
