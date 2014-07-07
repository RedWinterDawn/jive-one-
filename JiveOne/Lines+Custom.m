//
//  Lines+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Lines+Custom.h"

@implementation Lines (Custom)

+ (void)addLines:(NSArray *)lines pbxId:(NSString *)pbxId completed:(void (^)(BOOL success))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *line in lines) {
            if ([line isKindOfClass:[NSDictionary class]]) {
                [self addLine:line pbxId:pbxId withManagedContext:localContext sender:self];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];
}


+ (Lines *)addLine:(NSDictionary *)line pbxId:(NSString *)pbxId withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    NSString *lineId = line[@"id"];
    NSString *lineJrn;
    if ([lineId rangeOfString:@"jrn"].location == NSNotFound) {
        lineJrn = [NSString stringWithFormat:@"jrn:line::jive:%@:%@", pbxId, lineId];
    }
    else {
     //jrn:line::jive:0127d974-f9f3-0704-2dee-000100420001:0144931b-c692-f9fa-943a-000100620005
        lineJrn = lineId;
        NSArray *jrnExploded = [lineJrn componentsSeparatedByString:@":"];
        lineId = jrnExploded[jrnExploded.count - 1];
    }
    
    Lines *c_line = [Lines MR_findFirstByAttribute:@"jrn" withValue:lineJrn];
    if (c_line) {
        [self updateLine:c_line new_line:line];
    }
    else {
        
        c_line = [Lines MR_createInContext:context];
        c_line.pbxId = pbxId;
        c_line.displayName = line[@"displayName"] ? line[@"displayName"] : line[@"userName"];
        c_line.userName = line[@"userName"] ? line[@"userName"] : line[@"displayName"];
        c_line.groups = line[@"groups"];
        c_line.externsionNumber = line[@"extensionNumber"];
        c_line.jrn = lineJrn;
        c_line.lineId = lineId;
        c_line.state = [NSNumber numberWithInt:(int)JCPresenceTypeAvailable];
    }
    
    return c_line;
}

+ (void)updateLine:(Lines *)line new_line:(NSDictionary *)new_line
{
    line.userName = new_line[@"userName"];
    line.displayName = new_line[@"displayName"];
    line.groups = new_line[@"groups"];
}

@end
