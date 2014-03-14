//
//  JCConversationTableViewCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationTableViewCell.h"
#import "ConversationEntry+Custom.h"
#import "JCPersonCell.h"
#import "Common.h"

@implementation JCConversationTableViewCell

//NSString *const kCustomCellConversationTypeKeyPath = @"lastModified";
//NSString *const kCustomCellPersonPresenceTypeKeyPath = @"entityPresence";

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSArray *bundleArray = [[NSBundle mainBundle] loadNibNamed:@"JCPersonCell" owner:self options:nil];
        self = bundleArray[0];
        
    }
    return self;
}

-(void)setConversation:(Conversation *)conversation
{
    //[self removeObservers];
    if ([conversation isKindOfClass:[Conversation class]]) {
        
        _conversation = conversation;
        // add observer to the lastmodified property of the conversation
        [_conversation addObserver:self forKeyPath:kLastMofiedKeyPathForConversation options:NSKeyValueObservingOptionNew context:NULL];
        
        
        // get first entity that is not me: for 1:1 conversations, it will be the other person. For group, it can be anyone.
        NSArray *entitiesArray = (NSArray*)_conversation.entities;
        NSString *firstEntity = nil;
        for (NSString* entity in entitiesArray) {
            if (![entity isEqualToString:[[JCOmniPresence sharedInstance] me].urn]) {
                firstEntity = entity;
                break;
            }
        }
        
        ClientEntities * person = [[JCOmniPresence sharedInstance] entityByEntityId:firstEntity];
        if (person) {
            _person = person;
            // add observer to the person presence, even if it's a group, just so our app don't break.
            [_person addObserver:self forKeyPath:kPresenceKeyPathForClientEntity options:NSKeyValueObservingOptionNew context:NULL];
            
            // set cell title
            if ([_conversation.isGroup boolValue]) {
                self.conversationTitle.text = _conversation.name;
                
                // if it's a group, we don't need to set presence and we can hide it
                self.presenceView.hidden = YES;
            }
            else {
                self.conversationTitle.text = person.firstLastName;
                
                // if it's a person we want to set presence;
                self.presenceView.presenceType = (JCPresenceType)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
                self.presenceView.hidden = NO;
            }
        }
        
        // set the conversastion time label
        self.conversationTime.text = [Common dateFromTimestamp:_conversation.lastModified];
        
        // grab the last entry for the conversation and set in the snippet lable
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"conversationId ==[c] %@", _conversation.conversationId];
        ConversationEntry *lastEntry = [ConversationEntry MR_findFirstWithPredicate:predicate sortedBy:@"lastModified" ascending:NO];
        if (lastEntry) {
            self.conversationSnippet.text = lastEntry.message[@"raw"];
        }
    }
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
}

-(void)removeObservers
{
    @try {
        if (_conversation)
            [_conversation removeObserver:self forKeyPath:kLastMofiedKeyPathForConversation];
        if (_person)
            [_person removeObserver:self forKeyPath:kPresenceKeyPathForClientEntity];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kLastMofiedKeyPathForConversation]) {
        Conversation *conversation = (Conversation *)object;
        NSArray * conversationEntries = [ConversationEntry MR_findByAttribute:@"conversationId" withValue:conversation.conversationId andOrderBy:@"lastModified" ascending:NO];
        if (conversationEntries.count > 0) {
            ConversationEntry *lastEntry = conversationEntries[0];            
            self.conversationSnippet.text = lastEntry.message[@"raw"];
            //self.conversationTime.text = [self unixTimestapToDate:(int)lastEntry.lastModified];
        }
    }
    else if ([keyPath isEqualToString:kPresenceKeyPathForClientEntity]) {
        ClientEntities *person = (ClientEntities *)object;
        self.presenceView.presenceType = (JCPresenceType)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
    }
}

@end
