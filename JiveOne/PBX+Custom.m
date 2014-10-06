 //
//  PBX+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX+Custom.h"
#import "Lines+Custom.h"
#import "Common.h"

@implementation PBX (Custom)

+ (void)addPBXs:(NSArray *)pbxs userName:(NSString *)userName completed:(void (^)(BOOL success))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *pbx in pbxs) {
            if ([pbx isKindOfClass:[NSDictionary class]]) {
                [self addPBX:pbx userName:userName withManagedContext:localContext sender:self];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];
}
+ (PBX *)addPBX:(NSDictionary *)pbx userName:(NSString *)userName withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    NSString *self_url = pbx[@"self_pbx"] ? pbx[@"self_pbx"] : pbx[@"self"] ? pbx[@"self"] : @"";
	NSString *pbxId = pbx[@"pbxId"] ? pbx[@"pbxId"] : nil;
    if ([Common stringIsNilOrEmpty:self_url]) {
        if (pbx[@"id"]) {
            self_url = [NSString stringWithFormat:@"https://api.jive.com/jif/v1/pbx/id/%@", pbx[@"id"]];
        }
    }
	
	if (!pbxId)
	{
		//https://api.jive.com/jif/v1/pbx/id/01471162-f384-24f5-9351-000100420005
		NSArray *pbxArray = [self_url componentsSeparatedByString:@"jif/v1/pbx/id/"];
		pbxId = pbxArray[1];
	}
    
    PBX *c_pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:pbxId inContext:context];
    
    if (c_pbx) {
        [self updatePBX:c_pbx new_pbx:pbx];
    }
    else {
        
        c_pbx = [PBX MR_createInContext:context];
        c_pbx.pbxId = pbx[@"pbxId"] ? pbx[@"pbxId"] : pbxId;
        c_pbx.name = pbx[@"name"] ? pbx[@"name"] : @"";
        c_pbx.jrn = pbx[@"jrn"] ? pbx[@"jrn"] : @"";
        c_pbx.v5 = pbx[@"v5"] ? [NSNumber numberWithBool:[pbx[@"v5"] boolValue]] : false;
        c_pbx.selfUrl = self_url;
    }
    
    NSArray *lines = pbx[@"lines"];
    if (lines && lines.count > 0) {
        for (NSDictionary *line in lines) {
            [Lines addLine:line pbxId:c_pbx.pbxId userName:userName withManagedContext:context sender:nil];
        }
    }
    
    if (sender != self) {
        //[context MR_saveToPersistentStoreAndWait];
        return c_pbx;
    }
    else {
        return nil;
    }
}

+ (void)updatePBX:(PBX *)pbx new_pbx:(NSDictionary *)new_pbx
{
    pbx.pbxId = new_pbx[@"jrn"] ? new_pbx[@"jrn"] : new_pbx[@"id"] ;
    pbx.name = new_pbx[@"name"] ? new_pbx[@"name"] : @"";
    pbx.jrn = new_pbx[@"jrn"] ? new_pbx[@"jrn"] : new_pbx[@"id"];
    pbx.v5 = new_pbx[@"v5"] ? [NSNumber numberWithBool:[new_pbx[@"v5"] boolValue]] : pbx.v5;
}

+ (PBX *)fetchFirstPBX
{
    Lines *mailbox = [Lines MR_findFirst];
    return [PBX MR_findFirstByAttribute:@"pbxId" withValue:mailbox.pbxId];
}

@end
