//
//  JCMessagesViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationViewController.h"

#import <JCPhoneModule/JCProgressHUD.h>

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
@property (nonatomic, strong) NSString *forwardedMessageString;

@end

@implementation JCConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Forward", @"Forward") action:@selector(forward:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[menuItem]];
    
    self.inputToolbar.contentView.textView.placeHolder = NSLocalizedStringFromTable(@"Send SMS", @"Chat", nil);
    self.inputToolbar.contentView.leftBarButtonItem = nil;
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

- (void)viewDidAppear:(BOOL)animated
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
    
    if (_forwardedMessageString) {
        self.inputToolbar.contentView.textView.text = _forwardedMessageString;
        self.inputToolbar.contentView.rightBarButtonItem.enabled = TRUE;
    }
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
    JCMessageGroup *group = self.messageGroup;
    
    // The group may not have a resource group if there are multiple DIDs for the selected PBX, and
    // this is the first time a message is being sent to this recipient.
    if (!group.resourceId)
    {
        PBX *pbx = self.userManager.pbx;
        NSMutableArray *dids = pbx.dids.allObjects.mutableCopy;
        if (!dids || dids.count == 0 || !pbx.sendSMSMessages) {
            return; // We do not have a did to send to, or permission to send.
        }
        else if (dids.count == 1){
            [self sendSMSMessage:text group:group did:dids.firstObject];
        }
        else
        {
            [dids sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]]];
            NSMutableArray *titles = [NSMutableArray array];
            for (DID *did in dids) {
                [titles addObject:did.titleText];
            }
            
            NSString *title = NSLocalizedStringFromTable(@"Which number would you like to send from", @"Chat", nil);
            JCActionSheet *didOptions = [[JCActionSheet alloc] initWithTitle:title
                                                                   dismissed:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                                                       if (buttonIndex != actionSheet.cancelButtonIndex) {
                                                                           DID *did = [dids objectAtIndex:buttonIndex];
                                                                           [self sendSMSMessage:text
                                                                                          group:group
                                                                                            did:did];
                                                                       }
                                                                   }
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                otherButtons:titles];
            [didOptions show:self.view];
        }
    }
    else
    {
        DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:group.resourceId];
        if (did) {
            [self sendSMSMessage:text group:group did:did];
        } else {
            PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:group.resourceId];
            if (pbx) {
                // TODO: Send Chat Message.
            }
        }
    }
}

-(void)sendSMSMessage:(NSString *)message group:(JCMessageGroup *)group did:(DID *)did {
    [SMSMessage sendMessage:message toMessageGroup:group fromDid:did completion:^(BOOL success, SMSMessage *smsMessage, NSError *error) {
        if (success) {
            group.resourceId = smsMessage.did.jrn;
            group.groupId = smsMessage.messageGroupId;
            self.title = group.titleText;
            self.fetchedResultsController = nil;
            [self.collectionView reloadData];
            [self finishSendingMessageAnimated:YES];
        }else {
            [self showError:error];
        }
    }];
}

-(void)finishSendingMessageAnimated:(BOOL)animated
{
    if (_forwardedMessageString) {
        [self cancelForward:self];
        return;
    }
    
    [super finishSendingMessageAnimated:animated];
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

-(void)collectionView:(JCMessagesCollectionView *)collectionView didForwardCellAtIndexPath:(NSIndexPath *)indexPath
{
    id<JSQMessageData> object = [self objectAtIndexPath:indexPath];
    if ([object isKindOfClass:[Message class]]) {
        Message *message = (Message*) object;
        NSString *identifier = self.restorationIdentifier;
       
        JCConversationViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
        JCNavigationController *navController = [[JCNavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        navController.navigationBar.translucent = self.navigationController.navigationBar.translucent;
        navController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
        navController.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
        UIBarButtonItem *cancelButton = [[UIBarButtonItem  alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelForward:)];
        controller.navigationItem.leftBarButtonItem = cancelButton;
        controller.forwardedMessageString = message.text;
        //count for ipad transition
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
        controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:navController animated:YES completion:NULL];
    }
}

-(void) cancelForward:(id) sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)forward:(id)sender { }

#pragma mark - Setters -

-(void)setMessageGroup:(JCMessageGroup *)messageGroup
{
    _messageGroup = messageGroup;
    NSString *resourceId = messageGroup.resourceId;
    if (resourceId) {
        DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:resourceId];
        if (did) {
            [SMSMessage downloadMessagesForDID:did toMessageGroup:messageGroup completion:NULL];
        }
        else {
            PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:resourceId];
            if (pbx) {
                //TODO: Download Chat messages for the given conversation.
            }
        }
    }
    
    self.title = messageGroup.titleText;
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
        JCMessageGroup *messageGroup = self.messageGroup;
        NSPredicate *predicate = [Message predicateForMessagesWithGroupId:messageGroup.groupId
                                                               resourceId:messageGroup.resourceId
                                                                    pbxId:self.userManager.pbx.pbxId];
        
        NSFetchRequest *fetchRequest = [Message MR_requestAllWithPredicate:predicate inContext:context];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(date)) ascending:YES]];
        fetchRequest.includesSubentities = YES;
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        _fetchedResultsController.delegate = self;
        
        // Make sure the _fetched result controller has fetched data and reload
        // the table if sucessfull.
        __autoreleasing NSError *error = nil;
        if (![_fetchedResultsController performFetch:&error]) {
            NSLog(@"%@", [error description]);
        }
    }
    return _fetchedResultsController;
}

- (NSString *)senderId
{
    return self.messageGroup.resourceId;
}

- (NSString *)senderDisplayName
{
    return self.messageGroup.titleText;
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
