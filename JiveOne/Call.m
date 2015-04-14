//
//  Call.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Call.h"
#import "Contact.h"
#import "Line.h"
#import "JCPhoneNumberDataSource.h"
#import "LocalContact.h"
#import "JCMultiPersonPhoneNumber.h"

NSString *const kCallEntityName = @"Call";

@implementation Call

@end

@implementation Call (MagicalRecord)

+(void)addCallEntity:(NSString *)entityName line:(Line *)line lineSession:(JCLineSession *)session read:(BOOL)read
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Line *localLine = (Line *)[localContext objectWithID:line.objectID];
        Call *call = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:localContext];
        call.date   = [NSDate date];
        call.name   = session.number.name;
        call.number = session.number.dialableNumber;
        call.read   = read;
        call.line   = localLine;
        
        id <JCPhoneNumberDataSource> number = session.number;
        if (number && [number isKindOfClass:[Contact class]]) {
            call.contact = (Contact *)[localContext objectWithID:((Contact *)number).objectID];
        }
        else if(number && [number isKindOfClass:[LocalContact class]]) {
            [call addLocalContactsObject:(LocalContact *)[localContext objectWithID:((LocalContact *)number).objectID]];
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
//                [LocalContact localContactForAddressBookNumber:number context:localContext]
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

