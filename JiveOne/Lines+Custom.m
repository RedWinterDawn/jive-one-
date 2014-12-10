//
//  Lines+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Lines+Custom.h"
#import "ContactGroup.h"
#import "LineGroup.h"
#import "Common.h"
#import "PBX.h"
#import "User.h"

#import "NSDictionary+Validations.h"

NSString *const kLineResponseIdentifierKey      = @"id";
NSString *const kLineResponseLineNameKey        = @"lineName";
NSString *const kLineResponseDisplayNameKey     = @"displayName";
NSString *const kLineResponseExtensionNumberKey = @"extensionNumber";
NSString *const kLineResponseLineNumberKey      = @"lineNumber";
NSString *const kLineResponseJrnKey             = @"jrn";
NSString *const kLineResponseMailboxUrlKey      = @"self_mailbox";
NSString *const kLineResponseMailboxJrnKey      = @"mailbox_jrn";

@implementation Line (Custom)

+ (void)addLines:(NSArray *)linesData pbx:(PBX *)pbx completed:(void (^)(BOOL success))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (id object in linesData)
        {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [self addLine:(NSDictionary *)object pbx:pbx context:localContext];
            }
            else {
                completed(false);
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];
}

+ (Line *)addLine:(NSDictionary *)data pbx:(PBX *)pbx context:(NSManagedObjectContext *)context
{
    NSString *lineId = [data stringValueForKey:kLineResponseIdentifierKey];
    Line *line = [Line lineForLineId:lineId pbx:pbx context:context];
    
    NSString *displayName = [data stringValueForKey:kLineResponseLineNameKey];
    if (!displayName || displayName.isEmpty) {
        displayName = [data stringValueForKey:kLineResponseDisplayNameKey];
    }
    
    line.displayName = displayName;
    
    NSString *extensionNumber = [data stringValueForKey:kLineResponseExtensionNumberKey];
    if (!extensionNumber || extensionNumber.isEmpty) {
        extensionNumber = [data stringValueForKey:kLineResponseLineNumberKey];
    }
    
    line.externsionNumber = extensionNumber;
    line.jrn        = [data stringValueForKey:kLineResponseJrnKey];
    line.mailboxUrl = [data stringValueForKey:kLineResponseMailboxUrlKey];
    line.mailboxJrn = [data stringValueForKey:kLineResponseMailboxJrnKey];
    line.state      = [NSNumber numberWithInt:(int)JCPresenceTypeAvailable];
    
    return line;
}

+ (Line *)lineForLineId:(NSString *)lineId pbx:(PBX *)pbx context:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and lineId = %@", pbx, lineId];
    Line *line = [Line MR_findFirstWithPredicate:predicate inContext:context];
    if(!line)
    {
        line = [Line MR_createInContext:context];
        line.lineId = lineId;
        line.pbx = pbx;
        
        // Deprecated
        line.pbxId = pbx.pbxId;
        line.userName = pbx.user.jiveUserId;
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
