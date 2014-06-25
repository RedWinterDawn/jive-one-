//
//  PBX+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX+Custom.h"
#import "Lines+Custom.h"

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
    
    NSString *pbxId = pbx[@"id"];
    PBX *c_pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:pbxId];
    if (c_pbx) {
        [self updatePBX:c_pbx new_pbx:pbx];
    }
    else {
        
        c_pbx = [PBX MR_createInContext:context];
        c_pbx.pbxId = pbxId;
        c_pbx.name = pbx[@"name"];
    }
    
    NSArray *lines = pbx[@"lines"];
    if (lines && lines.count > 0) {
        for (NSDictionary *line in lines) {
            [Lines addLine:line pbxId:pbxId withManagedContext:context sender:nil];
        }
    }
    
    return c_pbx;
}

+ (void)updatePBX:(PBX *)pbx new_pbx:(NSDictionary *)new_pbx
{
    pbx.name = new_pbx[@"name"];
}

@end
