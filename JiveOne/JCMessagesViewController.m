//
//  JCMessagesViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessagesViewController.h"

// Libraries
#import <JSQMessagesViewController/JSQSystemSoundPlayer+JSQMessages.h>

// Models
#import "JCPerson.h"
#import "Message.h"
#import "SMSMessage.h"
#import "Conversation.h"
#import "JCUnknownNumber.h"
#import "LocalContact.h"
#import "SMSMessage+SMSClient.h"

// Views
#import "JCMessagesCollectionViewCell.h"

// Controllers
#import "JCMessageParticipantTableViewController.h"
#import "JCNavigationController.h"

@protocol JSQMessageViewControllerPrivate <NSObject>

@optional
- (void)jsq_configureMessagesViewController;
- (void)jsq_registerForNotifications:(BOOL)registerForNotifications;

@end

@interface JCMessagesViewController () <JSQMessageViewControllerPrivate, NSFetchedResultsControllerDelegate>
{
    // Support arrays for the NSFetchedResultController delegate methods.
    NSMutableArray *_sectionChanges;
    NSMutableArray *_itemChanges;
    
    // A list of participants
    NSArray *_participants;
}

@property (nonatomic, strong) NSArray *participants;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation JCMessagesViewController

- (void)viewDidLoad
{
    [self jsq_configureMessagesViewController];
    [self jsq_registerForNotifications:YES];
    
    //setting the background color of the messages view
    self.collectionView.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:239/255.0f alpha:1.0f];
    
    self.senderId           = [JCAuthenticationManager sharedInstance].jiveUserId;
    self.senderDisplayName  = [JCAuthenticationManager sharedInstance].line.name;
    self.senderNumber       = @"8013163336";
    
    // didId = 0142349c-fff3-719c-cb63-000100420002
    
    self.incomingCellIdentifier = @"incomingText";
    self.outgoingCellIdentifier = @"outgoingText";
    
    // Layout configurations
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeMake(40, 40);
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(40, 40);
    self.collectionView.collectionViewLayout.messageBubbleTextViewTextContainerInsets = UIEdgeInsetsMake(7.0f, 14.0f, 0.0f, 14.0f);
   
    self.inputToolbar.contentView.textView.placeHolder = NSLocalizedStringFromTable(@"Send SMS", @"JSQMessages", @"Placeholder text for the message input text view");
    
    if (!_messageGroupId) {
        JCMessageParticipantTableViewController *participantTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MessageParticipantsViewController"];
        participantTableViewController.delegate = self;
        [self presentDropdownViewController:participantTableViewController animated:YES];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", _messageGroupId];
        Message *message = [Message MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:NO];
        if ([message isKindOfClass:[SMSMessage class]]) {
            SMSMessage *smsMessage = (SMSMessage *)message;
            self.title = smsMessage.localContact.name;
            _participants = @[smsMessage.localContact];
        }
        [message.managedObjectContext refreshObject:message mergeChanges:NO];
        
        [SMSMessage downloadMessagesForDID:nil
                                    number:_messageGroupId
                                completion:^(BOOL success, NSError *error) {
                                    
                                }];
    }
    
    
}

+ (UINib *)nib
{
    return nil; // Override to use the storyboard.
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
    id<JCPerson> person = _participants.lastObject;
    [SMSMessage sendMessage:text toNumber:person.number fromDid:nil completion:^(BOOL success, NSError *error) {
     if (success) {
         [JSQSystemSoundPlayer jsq_playMessageSentSound];
         [self finishSendingMessageAnimated:YES];
     }else {
         [self showError:error];
     }
 }];
}

- (IBAction)simulateIncomingMsg:(id)sender {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextWithParent:self.fetchedResultsController.managedObjectContext];
    id<JCPerson> person = _participants.lastObject;
    Message *message;
    if ([person isKindOfClass:[JCUnknownNumber class]]) {
        JCUnknownNumber *unknowNumber = (JCUnknownNumber *)person;
        SMSMessage *smsMessage = [SMSMessage MR_createInContext:context];
        [smsMessage setNumber:unknowNumber.number name:unknowNumber.name];
        smsMessage.inbound = true;
        message = smsMessage;
    } else if ([person isKindOfClass:[LocalContact class]]) {
        LocalContact *localContact = (LocalContact *)person;
        SMSMessage *smsMessage = [SMSMessage MR_createInContext:context];
        [smsMessage setNumber:localContact.number name:localContact.name];
        smsMessage.inbound = true;
        message = smsMessage;
    }
    
    message.text = @"Ahhhh Things";
    message.read = TRUE;
    message.date = [NSDate date];
    
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
            
            //TODO: upload to the server here.
            
            [self finishSendingMessageAnimated:YES];
        } else {
            
        }
    }];
    
}

#pragma mark - Setters -

-(void)setParticipants:(NSArray *)participants
{
    // For now we only allow one participant...so for now, limit it to the first participant past.
    if (participants.count < 1) {
        return;
    }
    _participants = @[participants.firstObject];
    id<JCPerson> person = _participants.lastObject;
    self.title = person.name;
        
    // New SMS from a unknown number;
    if ([person isKindOfClass:[JCUnknownNumber class]]) {
        self.messageGroupId = ((JCUnknownNumber *)person).number;
    }
}

-(void)setMessageGroupId:(NSString *)conversationId
{
    _messageGroupId = conversationId;
    _fetchedResultsController = nil;
    [self.collectionView reloadData];
}

#pragma mark - Getters -

-(NSFetchedResultsController *)fetchedResultsController
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

#pragma mark - Private -

-(NSUInteger)count
{
    return self.fetchedResultsController.fetchedObjects.count;
}

-(Message *)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NSIndexPath *)indexPathOfObject:(id<NSObject>)object
{
    return [self.fetchedResultsController indexPathForObject:object];
}

#pragma mark - Delegate Handlers -

// This section is a set of methods from the JSQMessagesViewController superclass that help us
// define and control the display of the message. Thes are specific to the implementation.

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView
       messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self objectAtIndexPath:indexPath];
}

-(CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                  layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 23;
}

#pragma mark UICollectionViewDataSource

//  This section defines the bechavior of the collection view controller, defining to the Layout
//  controller how many sections we have, the number of items in each section and which cell should
//  be shown for each item. It leveraged the fetched results controller to get the sections, section
//  info and the object for each cell for the given section and index path.

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    if (sectionInfo)
        return [sectionInfo numberOfObjects];
    return 0;
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [collectionView.dataSource collectionView:collectionView messageDataForItemAtIndexPath:indexPath];
    BOOL isOutgoingMessage = ([message isKindOfClass:[SMSMessage class]]) ? !((SMSMessage *)message).isInbound : [message.senderId isEqualToString:self.senderId];
    NSString *cellIdentifier = isOutgoingMessage ? self.outgoingCellIdentifier : self.incomingCellIdentifier;
    JCMessagesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.delegate = collectionView;
    cell.incoming = !isOutgoingMessage;
    cell.textView.text = message.text;
    cell.detailLabel.text = message.detailText;
    
    cell.backgroundColor            = [UIColor clearColor];
    cell.layer.rasterizationScale   = [UIScreen mainScreen].scale;
    cell.layer.shouldRasterize      = YES;
    cell.textView.textColor         = [UIColor blackColor];
    cell.textView.dataDetectorTypes = UIDataDetectorTypeAll;
    
    return cell;
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
