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
#import "User.h"

@interface JCPhoneBook : NSObject

-(instancetype)initWithAddressBook:(JCAddressBook *)addressBook;

@property (nonatomic, readonly) JCAddressBook *addressBook;

// Search for a specific phone number and name in our Jive and Local Contacts phone books. If no
// contact is found
-(id<JCPhoneNumberDataSource>)phoneNumberForNumber:(NSString *)number
                                              name:(NSString *)name
                                            forPbx:(PBX *)pbx
                                     excludingLine:(Line *)line;

// Search for a specific name and number in our local contacts. If multiple contacts were
// encountered, and JCMultiPersonPhoneNumber object is returned, representing the aggregate contact.
// If no phone number is found, a nil result is returned.
-(id<JCPhoneNumberDataSource>)localPhoneNumberForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
                                                     context:(NSManagedObjectContext *)context;


-(void)phoneNumbersWithKeyword:(NSString *)keyword
                       forUser:(User *)user
                       forLine:(Line *)line
                   sortedByKey:sortedByKey
                     ascending:(BOOL)ascending
                    completion:(void (^)(NSArray *phoneNumbers))completion;

-(NSArray *)phoneNumbersWithKeyword:(NSString *)keyword
                            forUser:(User *)user
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
