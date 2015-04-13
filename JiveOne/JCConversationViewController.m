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
#import "JCAddressBookNumber.h"
#import "PBX.h"
#import "Line.h"
#import "JCPhoneBook.h"

// Views
#import "JCMessagesCollectionViewCell.h"
#import "JCActionSheet.h"

// Controllers
#import "JCMessageParticipantTableViewController.h"
#import "JCNavigationController.h"

#define MESSAGES_PARTICIPANT_VIEW_CONTROLLER @"MessageParticipantsViewController"

@interface JCConversationViewController () <NSFetchedResultsControllerDelegate>
{
    NSMutableArray *_sectionChanges;
    NSMutableArray *_itemChanges;
}

@property (nonatomic, strong) NSArray *participants;
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
    
    [self checkParticipants];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *messages = [Message MR_findAllWithPredicate:self.fetchedResultsController.fetchRequest.predicate inContext:localContext];
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
        id<JCPersonDataSource> person = _participants.lastObject;
        if (self.count == 0) {
            
            NSMutableArray *dids= [JCAuthenticationManager sharedInstance].pbx.dids.allObjects.mutableCopy;
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
             [dids sortUsingDescriptors:@[sortDescriptor]];
            NSMutableArray *titles = [NSMutableArray array];
            for (DID *did in dids) {
                [titles addObject:did.number.formattedPhoneNumber];
            }
            
            JCActionSheet *didOptions = [[JCActionSheet alloc] initWithTitle:@"Which number would you like to send from"
                                                                   dismissed:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                                                       if (buttonIndex != actionSheet.cancelButtonIndex) {
                                                                            DID *did = [dids objectAtIndex:buttonIndex];
                                                                           [self sendMessageWithSelectedDID:text toPerson:person fromDid:did];
                                                                       }
                                                                   }
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtons:titles];
            [didOptions show:self.view];
            
    } else {
        [self sendMessageWithSelectedDID:text toPerson:person fromDid:[JCAuthenticationManager sharedInstance].did];
    }
}

-(void)sendMessageWithSelectedDID:(NSString *)text toPerson:(id<JCPersonDataSource>)person fromDid:(DID *)did {
    NSLog(@"Sending Stuff : %@",did);
    
    [SMSMessage sendMessage:text toPerson:person fromDid:did completion:^(BOOL success, NSError *error) {
        if (success) {
            [self finishSendingMessageAnimated:YES];
        }else {
            [self showError:error];
        }
    }];
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"you selected the : %ld button", (long)buttonIndex);

}

#pragma mark - Setters -

-(void)setParticipants:(NSArray *)participants
{
    // For now we only allow one participant...so for now, limit it to the first participant past.
    if (participants.count < 1) {
        return;
    }
    _participants = @[participants.firstObject];
    id<JCPersonDataSource> person = _participants.lastObject;
    if ([person isKindOfClass:[LocalContact class]]) {
        NSString *name = person.name;
        if (name) {
            self.title = name;
        } else {
            
            id<JCPhoneNumberDataSource> phoneNumber = [self.phoneBook phoneNumberForNumber:person.number forLine:nil];
            self.title = phoneNumber.titleText;
        }
    } else {
        self.title = person.name;
    }
        
    // New SMS from a unknown number;
    if ([person isKindOfClass:[JCUnknownNumber class]]) {
        self.messageGroupId = ((JCUnknownNumber *)person).number;
    } else if([person isKindOfClass:[JCAddressBookNumber class]]) {
        self.messageGroupId = ((JCAddressBookNumber *)person).number.numericStringValue;
    }
}

-(void)setMessageGroupId:(NSString *)messageGroupId
{
    // Trigger a load of all the message data for that message group if there are messages for that
    // message group, and trigger a sync.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId CONTAINS[cd] %@", messageGroupId];
    Message *message = [Message MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:NO];
    if (message) {
        
        _messageGroupId = message.messageGroupId;
        
        // We are a SMS messages group, so we set the participant and request messages from the sms
        // client service.
        if ([message isKindOfClass:[SMSMessage class]])
        {
            SMSMessage *smsMessage = (SMSMessage *)message;
            [SMSMessage downloadMessagesForDID:smsMessage.did toPerson:smsMessage.localContact completion:NULL];
            self.title = smsMessage.localContact.name;
            self.participants = @[smsMessage.localContact];
        }
        
        // We are a conversation group, so we become a conversation UI.
        else if([message isKindOfClass:[Conversation class]])
        {
            // Yet to be defined conversation logic
        }
        
        // Reload the table from whatever it had before.
        _fetchedResultsController = nil;
        if (self.view.superview) {
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - Getters -

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        // Only do a fetch request if we have a conversation id.
        if (!_messageGroupId) {
            return nil;
        }
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        NSFetchRequest *fetchRequest = [Message MR_requestAllWhere:NSStringFromSelector(@selector(messageGroupId)) isEqualTo:_messageGroupId inContext:context];
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

- (void)checkParticipants
{
    // If we have a message id
    if (!_participants) {
        JCMessageParticipantTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:MESSAGES_PARTICIPANT_VIEW_CONTROLLER];
        viewController.view.frame = self.view.bounds;
        viewController.delegate = self;
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelMessageParticipantSelection:)];
        [self presentDropdownViewController:viewController leftBarButtonItem:nil rightBarButtonItem:doneButton maxHeight:self.view.bounds.size.height animated:YES];
        [viewController.searchBar becomeFirstResponder];
    }
}
                                       
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

-(void)messageParticipantTableViewController:(JCMessageParticipantTableViewController *)controller didSelectParticipants:(NSArray *)participants
{
    self.participants = participants;
    [self dismissDropdownViewControllerAnimated:YES completion:NULL];
}

@end
