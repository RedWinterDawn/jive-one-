//
//  JCMessagesViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationViewController.h"

// Models
#import "JCPersonDataSource.h"
#import "Message.h"
#import "SMSMessage.h"
#import "Conversation.h"
#import "JCUnknownNumber.h"
#import "PhoneNumber.h"
#import "SMSMessage+V5Client.h"
#import "BlockedNumber+V5Client.h"
#import "PBX.h"
#import "Line.h"
#import "JCPhoneBook.h"
#import "JCMessageGroup.h"

// Views
#import "JCMessagesCollectionViewCell.h"
#import "JCActionSheet.h"

// Controllers
#import "JCMessageParticipantTableViewController.h"
#import "JCNavigationController.h"
#import "JCConversationDetailsViewController.h"

// Categories
#import "NSString+Additions.h"

#define MESSAGES_PARTICIPANT_VIEW_CONTROLLER @"MessageParticipantsViewController"

@interface JCConversationViewController () <NSFetchedResultsControllerDelegate>
{
    NSMutableArray *_sectionChanges;
    NSMutableArray *_itemChanges;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readonly) DID *did;

@end

@implementation JCConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.inputToolbar.contentView.textView.placeHolder = NSLocalizedStringFromTable(@"Send SMS", @"Chat", nil);
    self.inputToolbar.contentView.leftBarButtonItem = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Determine if we should be showing the participant selector.
    if (!_messageGroup) {
        JCMessageParticipantTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:MESSAGES_PARTICIPANT_VIEW_CONTROLLER];
        viewController.view.frame = self.view.bounds;
        viewController.delegate = self;
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelMessageParticipantSelection:)];
        [self presentDropdownViewController:viewController leftBarButtonItem:doneButton rightBarButtonItem:nil maxHeight:self.view.bounds.size.height animated:YES];
        [viewController.searchBar becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSPredicate *predicate = self.fetchedResultsController.fetchRequest.predicate;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *messages = [Message MR_findAllWithPredicate:predicate inContext:localContext];
        for (Message *message in messages) {
            message.read = YES;
        }
    }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCConversationDetailsViewController class]]) {
        ((JCConversationDetailsViewController *)viewController).conversationGroup = self.messageGroup;
    }
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    _fetchedResultsController = nil;    // This can be rebuilt if we are in a low memory situation.
}

-(void)didPressSendButton:(UIButton *)button
          withMessageText:(NSString *)text
                 senderId:(NSString *)senderId
        senderDisplayName:(NSString *)senderDisplayName
                     date:(NSDate *)date
{
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    JCMessageGroup *messageGroup = self.messageGroup;
    if (self.count == 0) {
        NSMutableArray *dids = authenticationManager.pbx.dids.allObjects.mutableCopy;
        if (dids.count < 2){
             [self sendMessageWithSelectedDID:text toConversationGroup:messageGroup fromDid:authenticationManager.did];
        }
        else
        {
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
            [dids sortUsingDescriptors:@[sortDescriptor]];
            NSMutableArray *titles = [NSMutableArray array];
            for (DID *did in dids) {
                [titles addObject:did.titleText];
            }
            
            NSString *title = NSLocalizedStringFromTable(@"Which number would you like to send from", @"Chat", nil);
            JCActionSheet *didOptions = [[JCActionSheet alloc] initWithTitle:title
                                                                   dismissed:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                                                       if (buttonIndex != actionSheet.cancelButtonIndex) {
                                                                           DID *did = [dids objectAtIndex:buttonIndex];
                                                                           [self sendMessageWithSelectedDID:text
                                                                                        toConversationGroup:messageGroup
                                                                                                    fromDid:did];
                                                                       }
                                                                   }
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                otherButtons:titles];
            [didOptions show:self.view];
        }
    } else {
        [self sendMessageWithSelectedDID:text toConversationGroup:messageGroup fromDid:authenticationManager.did];
    }
       
}

-(void)sendMessageWithSelectedDID:(NSString *)text toConversationGroup:(JCMessageGroup *)conversationGroup fromDid:(DID *)did {
    [SMSMessage sendMessage:text toMessageGroup:conversationGroup fromDid:did completion:^(BOOL success, NSError *error) {
        if (success) {
            [self finishSendingMessageAnimated:YES];
        }else {
            [self showError:error];
        }
    }];
    
    [JCAlertView alertWithTitle:NSLocalizedStringFromTable(@"Set as default", @"Chat", nil)
                        message:NSLocalizedStringFromTable(@"Set this phone number as default phone number for all sms messages", @"Chat", nil)
                      dismissed:^(NSInteger buttonIndex) {
                          if (buttonIndex == 0) {
                              self.authenticationManager.did = self.did;
                              [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                  DID *currentDID = (DID *)[localContext objectWithID:self.did.objectID];
                                  NSArray *numbers = [DID MR_findAllWithPredicate:self.fetchedResultsController.fetchRequest.predicate inContext:localContext];
                                  for (DID *item in numbers) {
                                      if (currentDID == item){
                                          item.userDefault = TRUE;
                                      }
                                      else{
                                          item.userDefault = FALSE;
                                      }
                                  }
                              }];
                              
                          }
                      }
                showImmediately:YES
              cancelButtonTitle:NSLocalizedString(@"No", nil)
              otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
}

-(void)collectionView:(JCMessagesCollectionView *)collectionView didDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    id <JSQMessageData> object = [self objectAtIndexPath:indexPath];
    if ([object isKindOfClass:[Message class]]) {
        Message *message = (Message *)object;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            Message *localMessage = (Message *)[localContext objectWithID:message.objectID];
            [localMessage markForDeletion:NULL];
        }];
    }
}

#pragma mark - Setters -

-(void)setMessageGroup:(JCMessageGroup *)messageGroup
{
    _messageGroup = messageGroup;
    self.title = messageGroup.titleText;
    if (messageGroup.isSMS) {
        SMSMessage *smsMessage = (SMSMessage *)self.messageGroup.latestMessage;
        if (!smsMessage) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", messageGroup.messageGroupId];
            smsMessage = [SMSMessage MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:NO];
        }
        
        [SMSMessage downloadMessagesForDID:smsMessage.did toMessageGroup:messageGroup completion:NULL];
    }
    
    self.fetchedResultsController = nil;
    [self.collectionView reloadData];
}

#pragma mark - Getters -

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        // Only do a fetch request if we have a conversation id.
        if (!_messageGroup) {
            return nil;
        }
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        NSString *messageGroupId = self.messageGroup.messageGroupId;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@ AND markForDeletion = %@", messageGroupId, @NO];
        NSFetchRequest *fetchRequest = [Message MR_requestAllWithPredicate:predicate inContext:context ];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
        fetchRequest.includesSubentities = YES;
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        _fetchedResultsController.delegate = self;
        
        // Make sure the _fetched result controller has fetched data and reload
        // the table if sucessfull.
        __autoreleasing NSError *error = nil;
        if ([_fetchedResultsController performFetch:&error])
            [self.collectionView reloadData];
    }
    return _fetchedResultsController;
}

- (NSString *)senderId
{
    return self.authenticationManager.jiveUserId;
}

- (NSString *)senderNumber
{
    return self.did.number;
}

- (NSString *)senderDisplayName
{
    return self.authenticationManager.line.name;
}

- (DID *)did
{
    return self.authenticationManager.did;
}

#pragma mark - Private -
                                       
- (void)cancelMessageParticipantSelection:(id)sender
{
    [self dismissDropdownViewControllerAnimated:NO completion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (NSUInteger)count
{
    return self.fetchedResultsController.fetchedObjects.count;
}

- (id <JSQMessageData>)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NSIndexPath *)indexPathOfObject:(id<NSObject>)object
{
    return [self.fetchedResultsController indexPathForObject:object];
}

-(NSUInteger)numberOfSections
{
    return self.fetchedResultsController.sections.count;
}

-(NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    if (sectionInfo)
        return [sectionInfo numberOfObjects];
    return 0;
}

#pragma mark - Delegate Handlers -

-(BOOL)isIncomingMessageData:(id<JSQMessageData>)messageData collectionView:(JCMessagesCollectionView *)collectionView
{
    if ([messageData isKindOfClass:[SMSMessage class]]) {
        return ((SMSMessage *)messageData).isInbound;
    }
    return [super isIncomingMessageData:messageData collectionView:collectionView];
}

#pragma mark NSFetchedResultsControllerDelegate

//  These Delegate handlers receive updates from the fetched results controller, and will
//  dynamically update the collection view based on what the fetched results filters contain. Due to
//  the fact the collection view unlike the table view does not have a begin updates and an end
//  updates method, we have to managed the batch update process ourselves. We have two arrays that
//  hold section and item updates, and we process them each as updates come in, we then process them
//  as a batch at the end of the update cycle, updating the collection view in one batch.
//

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    _sectionChanges = [NSMutableArray new];
    _itemChanges = [NSMutableArray new];
}

-(void)controller:(NSFetchedResultsController *)controller
 didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    change[@(type)] = @(sectionIndex);
    [_sectionChanges addObject:change];
}

-(void)controller:(NSFetchedResultsController *)controller
  didChangeObject:(id)anObject
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            change[@(type)] = indexPath;
            break;
        }
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_itemChanges addObject:change];
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.collectionView performBatchUpdates:^{
        for (NSDictionary *change in _sectionChanges) {
            [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch(type) {
                    case NSFetchedResultsChangeInsert:
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    default:
                        break;
                }
            }];
        }
        for (NSDictionary *change in _itemChanges) {
            [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch(type) {
                    case NSFetchedResultsChangeInsert:
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        break;
                }
            }];
        }
    } completion:^(BOOL finished) {
        _sectionChanges = nil;
        _itemChanges = nil;
    }];
}

#pragma mark JCMessageParticipantTableViewControllerDelegate

-(void)messageParticipantTableViewController:(JCMessageParticipantTableViewController *)controller didSelectConversationGroup:(JCMessageGroup *)conversationGroup
{
    self.messageGroup = conversationGroup;
    [self dismissDropdownViewControllerAnimated:YES completion:NULL];
}

@end
