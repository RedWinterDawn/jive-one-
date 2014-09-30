//
//  LineConfiguration+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration+Custom.h"

@implementation LineConfiguration (Custom)

+ (void)addConfiguration:(NSDictionary *)config completed:(void (^)(BOOL success))completed
{
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		
		if (!localContext) {
			localContext = [NSManagedObjectContext MR_contextForCurrentThread];
		}
		
		
		LineConfiguration *lineConfig = [LineConfiguration MR_findFirst];
		if (lineConfig) {
			//[self updateLine:lineConfig pbxId:pbxId userName:userName new_line:line];
		}
		else {
			
			lineConfig = [LineConfiguration MR_createInContext:localContext];
			lineConfig.display = config[@"display"];
			lineConfig.outboundProxy = config[@"outboundProxy"];
			lineConfig.registrationHost = config[@"host"];
			lineConfig.sipPassword = config[@"password"];
			lineConfig.sipUsername = config[@"username"];
		}
			
		
	} completion:^(BOOL success, NSError *error) {
		completed(success);
	}];

}
@end
