//
//  LineConfiguration+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration+Custom.h"
#import <XMLDictionary/XMLDictionary.h>

@implementation LineConfiguration (Custom)

+ (void)addConfiguration:(NSDictionary *)config completed:(void (^)(BOOL success))completed
{
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		
		NSArray *dataArray = [config valueForKeyPath:@"branding.settings_data.core_data_list.account_list.account.data"];
		
		
		if (!localContext) {
			localContext = [NSManagedObjectContext MR_contextForCurrentThread];
		}
		
		LineConfiguration *lineConfig = [LineConfiguration MR_findFirst];
		if (!lineConfig) {
			lineConfig = [LineConfiguration MR_createInContext:localContext];
		}
		
		[dataArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *dic = (NSDictionary*)obj;
			if ([[dic objectForKey:@"_name"] isEqualToString:@"domain"]) {
				lineConfig.registrationHost = [dic objectForKey:@"_value"];
			}
			else if ([[dic objectForKey:@"_name"] isEqualToString:@"outboundProxy"]) {
				lineConfig.outboundProxy = [dic objectForKey:@"_value"];
			}
			else if ([[dic objectForKey:@"_name"] isEqualToString:@"username"]) {
				lineConfig.sipUsername = [dic objectForKey:@"_value"];
			}
			else if ([[dic objectForKey:@"_name"] isEqualToString:@"password"]) {
				lineConfig.sipPassword = [dic objectForKey:@"_value"];
			}
			else if ([[dic objectForKey:@"_name"] isEqualToString:@"display"]) {
				lineConfig.display = [dic objectForKey:@"_value"];
			}
			
		}];

			
		
	} completion:^(BOOL success, NSError *error) {
		completed(success);
	}];

}
@end
