//
//  ContactGroupAssociation+V5Client.m
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroupAssociation+V5Client.h"

#import "Contact.h"
#import "ContactGroup.h"

#import "JCV5ApiClient+Contacts.h"

@implementation ContactGroupAssociation (V5Client)

+(void)associateContact:(Contact *)contact toContactGroup:(ContactGroup *)group completion:(CompletionHandler)completion
{
    __block ContactGroupAssociation *association = [self associationForContact:contact group:group];
    association.markForUpdate = TRUE;
    association.markForDeletion = FALSE;
    
    [association.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave)
        {
            if (completion) {
                completion (contextDidSave, error);
            }
            return;
        }
        
        [JCV5ApiClient associatedContactGroupAssociations:@{group.groupId : @[association.contact.contactId]}
                                               completion:^(BOOL success, id response, NSError *error) {
                                                   if (success) {
                                                       [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                                           ContactGroupAssociation *localAssociation = (ContactGroupAssociation *)[localContext objectWithID:association.objectID];
                                                           localAssociation.markForUpdate = FALSE;
                                                           
                                                       } completion:^(BOOL contextDidSave, NSError *error) {
                                                           if (completion) {
                                                               completion (contextDidSave, error);
                                                           }
                                                       }];
                                                   }
                                                   else {
                                                       if (completion) {
                                                           completion (NO, error);
                                                       }
                                                   }
                                               }];
    }];
}

+(void)associateContacts:(NSArray *)contacts toContactGroup:(ContactGroup *)group completion:(CompletionHandler)completion
{
    NSMutableArray *associationsData = [NSMutableArray new];
    __block NSMutableArray *associations = [NSMutableArray new];
    for (id object in contacts) {
        if (![object isKindOfClass:[Contact class]]) {
            continue;
        }
        
        Contact *contact = (Contact *)object;
        ContactGroupAssociation *association = [self associationForContact:contact group:group];
        association.markForUpdate = TRUE;
        association.markForDeletion = FALSE;
        [associationsData addObject:association.contact.contactId];
        [associations addObject:association];
    }
    
    [group.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave)
        {
            if (completion) {
                completion (contextDidSave, error);
            }
            return;
        }
        
        [JCV5ApiClient associatedContactGroupAssociations: @{group.groupId : associationsData}
                                               completion:^(BOOL success, id response, NSError *error) {
                                                   if (success) {
                                                       [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                                           for (ContactGroupAssociation *association in associations) {
                                                               ContactGroupAssociation *localAssociation = (ContactGroupAssociation *)[localContext objectWithID:association.objectID];
                                                               localAssociation.markForUpdate = FALSE;
                                                           }
                                                       } completion:^(BOOL contextDidSave, NSError *error) {
                                                           if (completion) {
                                                               completion (contextDidSave, error);
                                                           }
                                                       }];
                                                   }
                                                   else {
                                                       if (completion) {
                                                           completion (NO, error);
                                                       }
                                                   }
                                               }];
    }];
}

+(void)disassociateContact:(Contact *)contact toContactGroup:(ContactGroup *)group completion:(CompletionHandler)completion
{
    ContactGroupAssociation *association = [self getAssociationForContact:contact group:group];
    if (!association) {
        if (completion) {
            completion (YES, nil);  // No associations to purge.
        }
        return;
    }
    
    association.markForUpdate = FALSE;
    association.markForDeletion = TRUE;
    
    [association.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave)
        {
            if (completion) {
                completion (contextDidSave, error);
            }
            return;
        }
        
        [JCV5ApiClient associatedContactGroupAssociations:@{group.groupId : @[association.contact.contactId]}
                                               completion:^(BOOL success, id response, NSError *error) {
                                                   if (success) {
                                                       [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                                           ContactGroupAssociation *localAssociation = (ContactGroupAssociation *)[localContext objectWithID:association.objectID];
                                                           [localContext deleteObject:localAssociation];
                                                           
                                                       } completion:^(BOOL contextDidSave, NSError *error) {
                                                           if (completion) {
                                                               completion (contextDidSave, error);
                                                           }
                                                       }];
                                                   }
                                                   else {
                                                       if (completion) {
                                                           completion (NO, error);
                                                       }
                                                   }
                                               }];
    }];
    
}

+(void)disassociateContacts:(NSArray *)contacts toContactGroup:(ContactGroup *)group completion:(CompletionHandler)completion
{
    NSMutableArray *associationsData = [NSMutableArray new];
    __block NSMutableArray *associations = [NSMutableArray new];
    for (id object in contacts) {
        if (![object isKindOfClass:[Contact class]]) {
            continue;
        }
        
        Contact *contact = (Contact *)object;
        ContactGroupAssociation *association = [self getAssociationForContact:contact group:group];
        if (associations) {
            association.markForUpdate = FALSE;
            association.markForDeletion = TRUE;
            [associationsData addObject:association.contact.contactId];
            [associations addObject:association];
        }
        
    }
    
    if (associations.count == 0) {
        if (completion) {
            completion (YES, nil);  // No associations to purge.
        }
        return;
    }
    
    [group.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave) {
            if (completion) {
                completion (contextDidSave, error);
            }
            return;
        }
        
        [JCV5ApiClient associatedContactGroupAssociations: @{group.groupId : associationsData}
                                               completion:^(BOOL success, id response, NSError *error) {
                                                   if (success) {
                                                       [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                                           for (ContactGroupAssociation *association in associations) {
                                                               ContactGroupAssociation *localAssociation = (ContactGroupAssociation *)[localContext objectWithID:association.objectID];
                                                               [localContext deleteObject:localAssociation];
                                                           }
                                                       } completion:^(BOOL contextDidSave, NSError *error) {
                                                           if (completion) {
                                                               completion (contextDidSave, error);
                                                           }
                                                       }];
                                                   }
                                                   else {
                                                       if (completion) {
                                                           completion (NO, error);
                                                       }
                                                   }
                                               }];
    }];
}

#pragma mark - Private -

+(ContactGroupAssociation *)associationForContact:(Contact *)contact group:(ContactGroup *)group
{
    ContactGroupAssociation *association = [self getAssociationForContact:contact group:group];
    if (association) {
        association = [ContactGroupAssociation MR_createEntityInContext:group.managedObjectContext];
        association.contact = contact;
        association.group = group;
    }
    return association;
}

+(ContactGroupAssociation *)getAssociationForContact:(Contact *)contact group:(ContactGroup *)group
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contact = %@ AND group = %@", contact, group];
    return [ContactGroupAssociation MR_findFirstWithPredicate:predicate inContext:group.managedObjectContext];
}

@end
