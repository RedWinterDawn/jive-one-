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

NSString *const kPBXResponseIdentifierKey = @"pbxId";
NSString *const kPBXResponseNameKey       = @"name";
NSString *const kPBXResponseV5Key         = @"v5";
NSString *const kPBXResponseLinesKey      = @"lines";

@implementation PBX (Custom)

/**
 * Recieves an array of PBXs and iterates over them, saving them to core data and returning an array of added PBXs.
 */
+ (void)addPBXs:(NSArray *)pbxsData user:(User *)user completed:(void (^)(BOOL success, NSArray *pbxs, NSError *error))completed
{
    __block NSMutableArray *pbxs = [NSMutableArray arrayWithCapacity:pbxsData.count];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *pbxData in pbxsData) {
            if ([pbxData isKindOfClass:[NSDictionary class]]) {
                PBX *pbx = [self addPBX:pbxData user:(User *)[localContext objectWithID:user.objectID] context:localContext];
                if (pbx) {
                    [pbxs addObject:pbx];
                }
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success, pbxs, error);
    }];
}

+ (PBX *)addPBX:(NSDictionary *)data user:(User *)user context:(NSManagedObjectContext *)context
{
    NSString *pbxId = [data stringValueForKey:kPBXResponseIdentifierKey];
    PBX *pbx = [PBX pbxForPbxId:pbxId user:user context:context];
    pbx.name    = [data stringValueForKey:kPBXResponseNameKey];
    pbx.v5      = [data boolValueForKey:kPBXResponseV5Key];
    
    id object = data[kPBXResponseLinesKey];
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray *lines = (NSArray *)object;
        if (lines && lines.count > 0) {
            for (id lineObject in lines) {
                if ([lineObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *lineData = (NSDictionary *)lineObject;
                    [Line addLine:lineData pbx:pbx context:context];
                }
            }
        }
    }
    return pbx;
}

+(PBX *)pbxForPbxId:(NSString *)pbxId user:(User *)user context:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@ and pbxId = %@", user, pbxId];
    PBX *pbx = [PBX MR_findFirstWithPredicate:predicate inContext:context];
    if (!pbx) {
        pbx = [PBX MR_createInContext:context];
        pbx.pbxId = pbxId;
        pbx.user = user;
    }
    return pbx;
}

@end
