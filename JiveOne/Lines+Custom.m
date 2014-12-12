//
//  Lines+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Lines+Custom.h"
#import "PBX.h"

NSString *const kLineResponseIdentifierKey      = @"id";
NSString *const kLineResponseLineNameKey        = @"lineName";
NSString *const kLineResponseLineNumberKey      = @"lineNumber";
NSString *const kLineResponseJrnKey             = @"jrn";
NSString *const kLineResponseMailboxUrlKey      = @"self_mailbox";
NSString *const kLineResponseMailboxJrnKey      = @"mailbox_jrn";

@implementation Line (Custom)

+ (void)addLines:(NSArray *)linesData pbx:(PBX *)pbx completed:(void (^)(BOOL success, NSError *error))completed
{
    __block NSManagedObjectID *objectId = pbx.objectID;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        PBX *localPbx = (PBX *)[localContext objectWithID:objectId];
        for (id object in linesData)
        {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [self addLine:(NSDictionary *)object pbx:localPbx];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        if (completed) {
            completed(success, error);
        }
    }];
}

+ (void)addLine:(NSDictionary *)data pbx:(PBX *)pbx
{
    NSString *jrn = [data stringValueForKey:kLineResponseJrnKey];
    if (!jrn) {
        return;
    }
    
    Line *line = [Line lineForJrn:jrn pbx:pbx];
    line.name        = [data stringValueForKey:kLineResponseLineNameKey];
    line.extension   = [data stringValueForKey:kLineResponseLineNumberKey];
    line.mailboxUrl  = [data stringValueForKey:kLineResponseMailboxUrlKey];
    line.mailboxJrn  = [data stringValueForKey:kLineResponseMailboxJrnKey];
    //line.state       = [NSNumber numberWithInt:(int)JCPresenceTypeAvailable];
    
    return;
}

+ (Line *)lineForJrn:(NSString *)jrn pbx:(PBX *)pbx
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and jrn = %@", pbx, jrn];
    Line *line = [Line MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
    if(!line)
    {
        line = [Line MR_createInContext:pbx.managedObjectContext];
        line.jrn = jrn;
        line.pbx = pbx;
    }
    return line;
}

@end

// Line Grouping.
//+ (Line *)addLine:(NSDictionary *)line pbxId:(NSString *)pbxId userName:(NSString *)userName withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
//{
//        c_line.groups = line[@"groups"];
//
//		if (line[@"groups"]) {
//			NSArray *groups = (NSArray *)line[@"groups"];
//			if (groups && groups.count > 0) {
//				for (NSDictionary *gr in groups) {
//
//					ContactGroup *cg = [ContactGroup MR_findFirstByAttribute:@"groupId" withValue:gr[@"id"] inContext:context];
//					if (cg) {
//						if (![cg.groupName isEqualToString:gr[@"name"]]) {
//							cg.groupName = gr[@"name"];
//						}
//					}
//					else {
//						cg = [ContactGroup MR_createInContext:context];
//						cg.groupId = gr[@"id"];
//						cg.groupName = gr[@"name"];
//					}
//
//					NSPredicate *pred = [NSPredicate predicateWithFormat:@"(groupId == %@) AND (lineId == %@)", cg.groupId, lineJrn];
//					LineGroup *lg = [LineGroup MR_findFirstWithPredicate:pred];
//					if (!lg) {
//						lg = [LineGroup MR_createInContext:context];
//						lg.lineId = c_line.jrn;
//						lg.groupId = cg.groupId;
//					}
//				}
//			}
//		}
//    //}
//
//    //return c_line;
//}
