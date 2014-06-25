//
//  Membership+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Membership+Custom.h"
#import "PBX+Custom.h"
#import "Lines+Custom.h"
@implementation Membership (Custom)

+ (void)addMemberships:(NSDictionary*)membership completed:(void (^)(BOOL suceeded))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NSString *jiveId = membership[@"jiveId"];
        
        for (NSDictionary *pbx in membership[@"tenantMembership"]) {
            
            NSString *pbxId = pbx[@"id"];
            NSString *membershipId = [NSString stringWithFormat:@"jrn:membership:jive:%@:%@", pbxId, jiveId];
            
            Membership *c_member = [Membership MR_findFirstByAttribute:@"membershipId" withValue:membershipId];
            
            if (!c_member) {
                c_member = [Membership MR_createInContext:localContext];
                c_member.jiveId = jiveId;
                c_member.pbxId = pbxId;
                c_member.membershipId = membershipId;
            }        
            
            [PBX addPBX:pbx withManagedContext:localContext sender:nil];
        }

        
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];
}

@end
