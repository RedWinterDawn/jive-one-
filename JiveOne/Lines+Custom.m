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

@implementation Lines (Custom)


- (NSString *)firstLetter
{
    [self willChangeValueForKey:@"firstLetter"];
    NSString *result = @"";
//    if ([self.isFavorite boolValue]) {
//        result = @"\u2605";
//    } else {
//        if (self.displayName.length == 0) {
//            result = @"";
//        }
//        else if (self.displayName.length == 1) {
//            result = self.displayName;
//        }
//        else {
            result = [self.displayName substringToIndex:1];
//        }
//    }
    
    [self didChangeValueForKey:@"firstLetter"];
    
    return [result uppercaseString];
}

+ (void)addLines:(NSArray *)lines pbxId:(NSString *)pbxId userName:(NSString *)userName completed:(void (^)(BOOL success))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *line in lines) {
            if ([line isKindOfClass:[NSDictionary class]]) {
                [self addLine:line pbxId:pbxId userName:userName withManagedContext:localContext sender:self];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];
}


+ (Lines *)addLine:(NSDictionary *)line pbxId:(NSString *)pbxId userName:(NSString *)userName withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    NSString *lineId = line[@"id"];
    NSString *lineJrn = line[@"jrn"];
    if ([lineId rangeOfString:@"jrn"].location == NSNotFound) {
        lineJrn = [NSString stringWithFormat:@"jrn:line::jive:%@:%@", pbxId, lineId];
    }
    else {
		if (lineId) {
			lineJrn = lineId;
		}
		
		NSArray *jrnExploded = [lineJrn componentsSeparatedByString:@":"];
		lineId = jrnExploded[jrnExploded.count - 1];
	}
    
    Lines *c_line = [Lines MR_findFirstByAttribute:@"jrn" withValue:lineJrn inContext:context];
    if (c_line) {
        [self updateLine:c_line pbxId:pbxId userName:userName new_line:line];
    }
    else {
        
        c_line = [Lines MR_createInContext:context];
        c_line.pbxId = pbxId;
        c_line.displayName = line[@"lineName"] ? line[@"lineName"] : line[@"displayName"] ? line[@"displayName"] : @"";
        c_line.userName = userName;
        c_line.groups = line[@"groups"];
        c_line.externsionNumber = line[@"extensionNumber"] ? line[@"extensionNumber"] : line[@"lineNumber"] ? line[@"lineNumber"] : @"";
        c_line.jrn = lineJrn;
        c_line.lineId = lineId;
		c_line.mailboxUrl = line[@"self_mailbox"];
		c_line.mailboxJrn = line[@"mailbox_jrn"];
        c_line.state = [NSNumber numberWithInt:(int)JCPresenceTypeAvailable];
		
		if (line[@"groups"]) {
			NSArray *groups = (NSArray *)line[@"groups"];
			if (groups && groups.count > 0) {
				for (NSDictionary *gr in groups) {
					
					ContactGroup *cg = [ContactGroup MR_findFirstByAttribute:@"groupId" withValue:gr[@"id"] inContext:context];
					if (cg) {
						if (![cg.groupName isEqualToString:gr[@"name"]]) {
							cg.groupName = gr[@"name"];
						}
					}
					else {
						cg = [ContactGroup MR_createInContext:context];
						cg.groupId = gr[@"id"];
						cg.groupName = gr[@"name"];
					}
									
					NSPredicate *pred = [NSPredicate predicateWithFormat:@"(groupId == %@) AND (lineId == %@)", cg.groupId, lineJrn];
					LineGroup *lg = [LineGroup MR_findFirstWithPredicate:pred];
					if (!lg) {
						lg = [LineGroup MR_createInContext:context];
						lg.lineId = c_line.jrn;
						lg.groupId = cg.groupId;
					}				
				}
			}
		}
    }
    
    return c_line;
}

+ (void)updateLine:(Lines *)line pbxId:(NSString *)pbxId userName:(NSString *)userName new_line:(NSDictionary *)new_line
{
    if ([Common stringIsNilOrEmpty:line.userName] && ![Common stringIsNilOrEmpty:userName]) {
		line.userName = userName;
	}
	
	if ([Common stringIsNilOrEmpty:line.userName]) {
		line.displayName = new_line[@"displayName"];
	}
	
    line.groups = new_line[@"groups"];
}

@end
