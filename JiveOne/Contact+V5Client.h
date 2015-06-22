//
//  Contact+V5Client.h
//  JiveOne
//
//  Created by Robert Barclay on 6/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"

@interface Contact (V5Client)

// Returns the data structure expected by the Server for POST or PUT operations when converted to JSON
@property (nonatomic, readonly) NSDictionary *serializedData;

/* ========================================================*/
/* ====================== Contact Sync ====================*/
/* ========================================================*/

/* Syncs all the data, fist deleting acy contacts that are marked for deletion, then uploading any
   contacts that are marked for upload, then download all contacts. */
+ (void)syncContactsForUser:(User *)user completion:(CompletionHandler)completion;

/* Syncs a contact. If the contact is marked for upload, it will perform the upload, updating the 
   contact with the data from the server. If it does not need to be uploaded, it downloads it. */
+ (void)syncContact:(Contact *)contact completion:(CompletionHandler)completion;

/* ========================================================*/
/* ===================== Contact Upload ===================*/
/* ========================================================*/

/* Marks the contact as to needing to be updated. If there is an active internet connection, it will
   upload the contact, syncing the server to what is local. If there is an etag mismatch, it will 
   fail with an error. If there is not internet connection, the contact is saved being marked
   for update, and will be updated during the next synce operation. */
- (void)markForUpdate:(CompletionHandler)completion;

/* ========================================================*/
/* ===================== Contact Delete ===================*/
/* ========================================================*/

/* Marks the contact for deletion. If there is an active internet connection, it will delete the 
   contact from the server. If there is not internet connection, the contact is saved being marked 
   for deletion, and will be removed during the next synce operation. */
- (void)markForDeletion:(CompletionHandler)completion;

@end
