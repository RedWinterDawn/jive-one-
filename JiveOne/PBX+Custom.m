 //
//  PBX+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX+Custom.h"
#import "Lines+Custom.h"
#import "User.h"
#import "JCV5ApiClient.h"

NSString *const kPBXInfoRequestPath       = @"/jif/v1/user/jiveId/%@?depth=1";
NSString *const kPBXInfoRequestResultKey  = @"userPbxs";

NSString *const kPBXResponseIdentifierKey = @"pbxId";
NSString *const kPBXResponseNameKey       = @"name";
NSString *const kPBXResponseV5Key         = @"v5";
NSString *const kPBXResponseLinesKey      = @"lines";

@implementation PBX (Custom)

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
                    if ([responseObject isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *result = (NSDictionary *)responseObject;
                        id object = [result objectForKey:kPBXInfoRequestResultKey];
                        if ([object isKindOfClass:[NSArray class]]) {
                            [PBX addPBXs:(NSArray *)object user:user completed:completion];
                        }
                        else {
                            completion(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientResponseParseErrorCode reason:@"Invalid pbx response object."]);
                        }
                    }
                    else {
                        completion(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientResponseParseErrorCode reason:@"Invalid pbxs response object."]);
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    completion(NO, [JCV5ApiClientError errorWithCode:JCV5ApiClientRequestErrorCode reason:error.localizedDescription]);
                }];
}

/**
 * Recieves an array of PBXs and iterates over them, saving them to core data and returning an array of added PBXs.
 */
+ (void)addPBXs:(NSArray *)pbxsData user:(User *)user completed:(void (^)(BOOL success, NSError *error))complete
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        User *localUser = (User *)[localContext objectWithID:user.objectID];
        for (NSDictionary *pbxData in pbxsData) {
            if ([pbxData isKindOfClass:[NSDictionary class]]) {
                [PBX addPBX:pbxData user:localUser];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        if (complete) {
            complete(success, error);
        }
    }];
}

+ (void)addPBX:(NSDictionary *)data user:(User *)user
{
    NSString *pbxId = [data stringValueForKey:kPBXResponseIdentifierKey];
    PBX *pbx = [PBX pbxForPbxId:pbxId user:user];
    pbx.name = [data stringValueForKey:kPBXResponseNameKey];
    pbx.v5   = [data boolValueForKey:kPBXResponseV5Key];
    
    id object = data[kPBXResponseLinesKey];
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray *lines = (NSArray *)object;
        if (lines && lines.count > 0) {
            for (id lineObject in lines) {
                if ([lineObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *lineData = (NSDictionary *)lineObject;
                    [Line addLine:lineData pbx:pbx];
                }
            }
        }
    }
}

+(PBX *)pbxForPbxId:(NSString *)pbxId user:(User *)user
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

@end
