//
//  JCConversationTableViewCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationTableViewCell.h"
#import "ConversationEntry+Custom.h"

@implementation JCConversationTableViewCell

NSString *const kCustomCellConversationTypeKeyPath = @"lastModified";

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
        
        if (!_conversation.isGroup) {
            NSArray *entitiesArray = (NSArray*)_conversation.entities;
            NSString *firstEntity = nil;
            
            for (NSString* entity in entitiesArray) {
                if (![entity isEqualToString:[[JCOmniPresence sharedInstance] me].urn]) {
                    firstEntity = entity;
                }
            }
            
            ClientEntities * person = [[JCOmniPresence sharedInstance] entityByEntityId:firstEntity];
            
            if (person) {
                self.conversationTitle.text = person.firstLastName;
            }
        }
        else
        {
            self.conversationTitle.text = [NSString stringWithFormat:@"%@", _conversation.name];
        }
        
        if ([_conversation.conversationId isEqualToString:@"permanentrooms:896"]) {
            NSString *ny = @"";
        }
        
        self.conversationTime.text = [self unixTimestapToDate:_conversation.lastModified];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"conversationId ==[c] %@", _conversation.conversationId];
        ConversationEntry *lastEntry = [ConversationEntry MR_findFirstWithPredicate:predicate sortedBy:@"lastModified" ascending:NO];
        if (lastEntry) {
            self.conversationSnippet.text = lastEntry.message[@"raw"];
        }
        
        [_conversation addObserver:self forKeyPath:kCustomCellConversationTypeKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
}

-(void)removeObservers
{
    if (_conversation)
        [_conversation removeObserver:self forKeyPath:kCustomCellConversationTypeKeyPath];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kCustomCellConversationTypeKeyPath]) {
        Conversation *conversation = (Conversation *)object;
        NSArray * conversationEntries = [ConversationEntry MR_findByAttribute:@"conversationId" withValue:conversation.conversationId andOrderBy:@"lastModified" ascending:NO];
        if (conversationEntries.count > 0) {
            ConversationEntry *lastEntry = conversationEntries[0];            
            self.conversationSnippet.text = lastEntry.message[@"raw"];
            //self.conversationTime.text = [self unixTimestapToDate:(int)lastEntry.lastModified];
        }
        
        
    }
}

- (NSString *)unixTimestapToDate:(NSNumber *)timestamp
{
    
    NSTimeInterval timeInterval = [timestamp longLongValue]/1000;
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970: timeInterval];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSTimeZone *timezone = [NSTimeZone defaultTimeZone];
    formatter.timeZone = timezone;
    return [formatter stringFromDate:date];
}


@end
