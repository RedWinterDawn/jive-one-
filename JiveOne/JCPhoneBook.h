//
//  JCPhoneBook.h
//  JiveOne
//
//  The JCPhoneBook objects provides an abastraction layer to requesting contact information from
//  both the core data managed contacts list and ABAddressBook backed data sets.
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

// Protocols
#import "JCPhoneNumberDataSource.h"

// Dependancies
#import "JCAddressBook.h"
#import "Line.h"

@interface JCPhoneBook : NSObject

-(instancetype)initWithAddressBook:(JCAddressBook *)addressBook;

@property (nonatomic, readonly) JCAddressBook *addressBook;

// Search for a specific phone number in our Jive and Local Contacts Phone books.
-(id<JCPhoneNumberDataSource>)phoneNumberForNumber:(NSString *)number forLine:(Line *)line;

// Search for a specific phone number and name in our Jive and Local Contacts phone books.
-(id<JCPhoneNumberDataSource>)phoneNumberForName:(NSString *)name number:(NSString *)number forLine:(Line *)line;


-(void)phoneNumbersWithKeyword:(NSString *)keyword
                       forLine:(Line *)line
                   sortedByKey:sortedByKey
                     ascending:(BOOL)ascending
                    completion:(void (^)(NSArray *phoneNumbers))completion;

-(NSArray *)phoneNumbersWithKeyword:(NSString *)keyword
                            forLine:(Line *)line
                        sortedByKey:sortedByKey
                          ascending:(BOOL)ascending;

@end

@interface JCPhoneBook (Singleton)

+(instancetype)sharedPhoneBook;

@end

@interface UIViewController (JCPhoneBook)

@property(nonatomic, strong) JCPhoneBook *phoneBook;

@end
