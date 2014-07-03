//
//  PBX+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX+Custom.h"
#import "Lines+Custom.h"
#import "Mailbox+Custom.h"

@implementation PBX (Custom)

+ (void)addPBXs:(NSArray *)pbxs completed:(void (^)(BOOL success))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *pbx in pbxs) {
            if ([pbx isKindOfClass:[NSDictionary class]]) {
                [self addPBX:pbx withManagedContext:localContext sender:self];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];
}
+ (PBX *)addPBX:(NSDictionary *)pbx withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    NSString *self_url = pbx[@"self_pbx"] ? pbx[@"self_pbx"] : pbx[@"self"] ? pbx[@"self"] : @"";
    PBX *c_pbx = [PBX MR_findFirstByAttribute:@"selfUrl" withValue:self_url inContext:context];
    
    if (c_pbx) {
        [self updatePBX:c_pbx new_pbx:pbx];
    }
    else {
        
        c_pbx = [PBX MR_createInContext:context];
        c_pbx.pbxId = pbx[@"jrn"] ? pbx[@"jrn"] : @"";
        c_pbx.name = pbx[@"name"] ? pbx[@"name"] : @"";
        c_pbx.jrn = pbx[@"jrn"] ? pbx[@"jrn"] : @"";
        c_pbx.v5 = pbx[@"v5"] ? [NSNumber numberWithBool:[pbx[@"v5"] boolValue]] : false;
        c_pbx.selfUrl = self_url;
    }
    
    NSArray *mailboxes = pbx[@"extensions"];
    if (mailboxes && mailboxes.count > 0) {
        for (NSDictionary *mailbox in mailboxes) {
            [Mailbox addMailbox:mailbox pbxUrl:self_url withManagedContext:context sender:nil];
        }
    }
    
    if (sender != self) {
        [context MR_saveToPersistentStoreAndWait];
        return c_pbx;
    }
    else {
        return nil;
    }
}

+ (void)updatePBX:(PBX *)pbx new_pbx:(NSDictionary *)new_pbx
{
    pbx.pbxId = new_pbx[@"jrn"] ? new_pbx[@"jrn"] : @"";
    pbx.name = new_pbx[@"name"] ? new_pbx[@"name"] : @"";
    pbx.jrn = new_pbx[@"jrn"] ? new_pbx[@"jrn"] : @"";
    pbx.v5 = new_pbx[@"v5"] ? [NSNumber numberWithBool:[new_pbx[@"v5"] boolValue]] : false;
}

@end
