//
//  ContactGroup+V5Client.h
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroup.h"

@class Contact;

@interface ContactGroup (V5Client)

// Returns the data structure expected by the Server for POST or PUT operations when converted to JSON
@property (nonatomic, readonly) NSDictionary *serializedData;

/* ========================================================*/
/* ====================== Contact Sync ====================*/
/* ========================================================*/

/* Syncs all the data, fist deleting acy contacts that are marked for deletion, then uploading any
 contacts that are marked for upload, then download all contacts. */
+ (void)syncContactGroupsForUser:(User *)user completion:(CompletionHandler)completion;

/* Syncs a contact. If the contact is marked for upload, it will perform the upload, updating the
 contact with the data from the server. If it does not need to be uploaded, it downloads it. */
+ (void)syncContactGroup:(ContactGroup *)contact completion:(CompletionHandler)completion;

/* ========================================================*/
/* ================= Contact Group Upload =================*/
/* ========================================================*/

/* Marks the contact group as to needing to be updated. If there is an active internet connection, 
 it will upload the contact group, syncing the server to what is local. If there is no internet 
 connection, the contact group is saved being marked for update, and will be updated during the next 
 synce operation. */
-(void)markForUpdate:(CompletionHandler)completion;

/* ========================================================*/
/* ================= Contact Group Delete =================*/
/* ========================================================*/

/* Marks the contact group for deletion. If there is an active internet connection, it will delete 
 the contact group from the server. If there is not internet connection, the contact group is saved 
 being marked for deletion, and will be removed during the next sync operation. */
-(void)markForDeletion:(CompletionHandler)completion;


@end
