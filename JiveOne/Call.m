//
//  Call.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Call.h"
#import "InternalExtension.h"
#import "Line.h"
#import "JCPhoneNumberDataSource.h"
#import "PhoneNumber.h"
#import "JCMultiPersonPhoneNumber.h"

NSString *const kCallEntityName = @"Call";

@implementation Call

@end

@implementation Call (MagicalRecord)

+(void)addCallEntity:(NSString *)entityName line:(Line *)line lineSession:(JCLineSession *)session read:(BOOL)read
{
    id <JCPhoneNumberDataSource> number = session.number;
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        Call *call = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:localContext];
        call.date   = [NSDate date];
        call.name   = number.name;
        call.number = number.dialableNumber;
        call.read   = read;
        call.line   = localLine;
        
        if (number && [number isKindOfClass:[InternalExtension class]]) {
            call.internalExtension = (InternalExtension *)[localContext objectWithID:((InternalExtension *)number).objectID];
        }
        else if(number && [number isKindOfClass:[PhoneNumber class]]) {
            [call addPhoneNumbersObject:(PhoneNumber *)[localContext objectWithID:((PhoneNumber *)number).objectID]];
        } else {
//            if ([number isKindOfClass:[JCMultiPersonPhoneNumber class]]) {
//                NSArray *phoneNumbers = ((JCMultiPersonPhoneNumber *)number).phoneNumbers;
//                for ( in phoneNumbers) {
//                    <#statements#>
//                }
//                
//                
//            }
//            
//            
//            
//            
//            if ([number isKindOfClass:[JCPhoneNumber class]]) {
//                
//              
//                
//                
//                
//            }
            
            //TODO: We need to find a local contact or jive contact while we are saving.
        }
        
    } completion:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"%@ Call Event Insert Error:%@", entityName, [error description]);
        }
    }];
}

@end

