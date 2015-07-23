//
//  ContactGroupAssociation+V5Client.h
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroupAssociation.h"

@interface ContactGroupAssociation (V5Client)

+(void)associateContact:(Contact *)contact
         toContactGroup:(ContactGroup *)group
             completion:(CompletionHandler)completion;

+(void)associateContacts:(NSArray *)contacts
          toContactGroup:(ContactGroup *)group
              completion:(CompletionHandler)completion;

+(void)disassociateContact:(Contact *)contact
            toContactGroup:(ContactGroup *)group
                completion:(CompletionHandler)completion;

+(void)disassociateContacts:(NSArray *)contacts
             toContactGroup:(ContactGroup *)group
                 completion:(CompletionHandler)completion;

+(ContactGroupAssociation *)associationForContact:(Contact *)contact
                                             group:(ContactGroup *)group;

+(ContactGroupAssociation *)getAssociationForContact:(Contact *)contact
                                                group:(ContactGroup *)group;

@end
