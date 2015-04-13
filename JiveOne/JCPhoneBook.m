//
//  JCPhoneBook.m
//  JiveOne
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneBook.h"

#import "JCUnknownNumber.h"
#import "JCMultiPersonPhoneNumber.h"
#import "PBX.h"

@interface JCPhoneBook ()
{
    JCAddressBook *_addressBook;
}

@end

@implementation JCPhoneBook

-(instancetype)initWithAddressBook:(JCAddressBook *)addressBook
{
    self = [super init];
    if (self) {
        _addressBook = addressBook;
    }
    return self;
}

-(instancetype)init
{
    return [self initWithAddressBook:[JCAddressBook sharedAddressBook]];
}

-(id<JCPhoneNumberDataSource>)phoneNumberForNumber:(NSString *)number forLine:(Line *)line;
{
    return [self phoneNumberForName:nil number:number forLine:line];
}

-(id<JCPhoneNumberDataSource>)phoneNumberForName:(NSString *)name number:(NSString *)number forLine:(Line *)line;
{
    // We must at least have a number.
    if (!number) {
        return nil;
    }
    
    // If we have a contacts, the number is the extension. Since extensions are unique to a line,
    // and contacts represent a line rather than an person entity, and the line has a name
    // representing the caller id, we only search on the basis of the extension.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbxId = %@ AND jrn != %@ AND extension = %@", line.pbx.pbxId, line.jrn, number];
    JiveContact *contact = [JiveContact MR_findFirstWithPredicate:predicate];
    if (contact) {
        return contact;
    }
    
    
    // TODO: search for the local contact record.....possibly combine with local address book.
    
    // Search the phones local address book.
    if (name) {
        predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR number CONTAINS[cd] = %@", name, number];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"number CONTAINS[cd] %@", number];
    }
    NSArray *array = [_addressBook fetchNumbersWithPredicate:predicate sortedByKey:@"name" ascending:YES];
    if (array.count > 0) {
        if (array.count > 1) {
            return [[JCMultiPersonPhoneNumber alloc] initWithPhoneNumbers:array];
        }
        else {
            return array.firstObject;
        }
    }
    
    return [JCUnknownNumber unknownNumberWithNumber:number];
}

@end
