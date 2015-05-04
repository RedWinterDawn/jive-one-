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
#import "LocalContact.h"
#import "SMSMessage+V5Client.h"
#import "PBX.h"
#import "Line.h"
#import "JCPhoneBook.h"

// Views
#import "JCMessagesCollectionViewCell.h"
#import "JCActionSheet.h"

// Controllers
#import "JCMessageParticipantTableViewController.h"
#import "JCNavigationController.h"

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
    
    self.inputToolbar.contentView.textView.placeHolder = NSLocalizedString(@"Send SMS", nil);
    self.inputToolbar.contentView.leftBarButtonItem = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Determine if we should be showing the participant selector.
    if (!_conversationGroup) {
        JCMessageParticipantTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:MESSAGES_PARTICIPANT_VIEW_CONTROLLER];
        viewController.view.frame = self.view.bounds;
        viewController.delegate = self;
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelMessageParticipantSelection:)];
        [self presentDropdownViewController:viewController leftBarButtonItem:nil rightBarButtonItem:doneButton maxHeight:self.view.bounds.size.height animated:YES];
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
    } completion:^(BOOL success, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSMSMessagesDidUpdateNotification object:nil];
    }];
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
    id<JCConversationGroupObject> conversationGroup = self.conversationGroup;
    if (self.count == 0) {
        NSMutableArray *dids = authenticationManager.pbx.dids.allObjects.mutableCopy;
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        [dids sortUsingDescriptors:@[sortDescriptor]];
        NSMutableArray *titles = [NSMutableArray array];
        for (DID *did in dids) {
            [titles addObject:did.titleText];
        }
            
        JCActionSheet *didOptions = [[JCActionSheet alloc] initWithTitle:@"Which number would you like to send from"
                                                               dismissed:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                                                   if (buttonIndex != actionSheet.cancelButtonIndex) {
                                                                       DID *did = [dids objectAtIndex:buttonIndex];
                                                                       [self sendMessageWithSelectedDID:text toConversationGroup:conversationGroup fromDid:did];
                                                                    }
                                                               }
                                                       cancelButtonTitle:@"Cancel"
                                                            otherButtons:titles];
        [didOptions show:self.view];
    } else {
        [self sendMessageWithSelectedDID:text toConversationGroup:conversationGroup fromDid:authenticationManager.did];
    }
       
}

-(void)sendMessageWithSelectedDID:(NSString *)text toConversationGroup:(id<JCConversationGroupObject>)conversationGroup fromDid:(DID *)did {
    [SMSMessage sendMessage:text toConversationGroup:conversationGroup fromDid:did completion:^(BOOL success, NSError *error) {
        if (success) {
            [self finishSendingMessageAnimated:YES];
        }else {
            [self showError:error];
        }
    }];
    
    [JCAlertView alertWithTitle:@"Set as default"
                        message:@"Set this phone number as default phone number for all sms messages"
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
              cancelButtonTitle:@"No"
              otherButtonTitles:@"Yes", nil];
}

#pragma mark - Setters -

-(void)setConversationGroup:(id<JCConversationGroupObject>)conversationGroup
{
    _conversationGroup = conversationGroup;
    self.title = conversationGroup.titleText;
    if (conversationGroup.isSMS) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", conversationGroup.conversationGroupId];
        SMSMessage *message = [SMSMessage MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:NO];
        [SMSMessage downloadMessagesForDID:message.did toConversationGroup:conversationGroup completion:NULL];
    }
}

#pragma mark - Getters -

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        // Only do a fetch request if we have a conversation id.
        if (!_conversationGroup) {
            return nil;
        }
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        NSString *conversationGroupId = self.conversationGroup.conversationGroupId;
        NSFetchRequest *fetchRequest = [Message MR_requestAllWhere:NSStringFromSelector(@selector(messageGroupId)) isEqualTo:conversationGroupId inContext:context];
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
    return [JCAuthenticationManager sharedInstance].jiveUserId;
}

- (NSString *)senderNumber
{
    return self.did.number;
}

- (NSString *)senderDisplayName
{
    return [JCAuthenticationManager sharedInstance].line.name;
}

- (DID *)did
{
    return [JCAuthenticationManager sharedInstance].did;
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

-(void)messageParticipantTableViewController:(JCMessageParticipantTableViewController *)controller didSelectConversationGroup:(id<JCConversationGroupObject>)conversationGroup
{
    self.conversationGroup = conversationGroup;
    [self dismissDropdownViewControllerAnimated:YES completion:NULL];
}

@end
