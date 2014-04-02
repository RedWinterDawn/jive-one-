//
//  JCConversationTableViewCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationTableViewCell.h"
#import "ConversationEntry+Custom.h"
#import <SDWebImage/UIImageView+WebCache.h>
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
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
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
                
                // if it's a group, we don't need to set presence and we can hide it and we can move our
                // name label origin to the right.
                self.presenceView.hidden = YES;
                
                [self createComposedImageForGroup];
            }
            else {
                self.conversationTitle.text = person.firstLastName;
                
                // if it's a person we want to set presence;
                self.presenceView.presenceType = (JCPresenceType)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
                self.presenceView.hidden = NO;
                
                UIImageView *singleImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                [singleImage setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                [self.conversationThumbnailView addSubview:singleImage];
                //[self.conversationImage setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
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
        
        [self adjustTitlePositionPresenceVisibility];
    }
}

- (void) adjustTitlePositionPresenceVisibility
{
    if (self.presenceView.hidden) {
        self.presenceWidth.constant = .0f;
        self.presenceSpacing.constant = .0f;
        CGFloat current = self.titleWidth.constant;
        current = current + 16.0f;
        self.titleWidth.constant = current;
    }
    else
    {
        self.presenceWidth.constant = 16.0f;
        self.presenceSpacing.constant = .0f;
        CGFloat current = self.titleWidth.constant;
        current = current - 16.0f;
        self.titleWidth.constant = current;
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



- (void)createComposedImageForGroup
{
    NSArray *entities = (NSArray *)self.conversation.entities;
    int count = 0;
    
    //UIView *compositeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    
    for (NSString* entity in self.conversation.entities) {
        ClientEntities *person = [ClientEntities MR_findFirstByAttribute:@"entityId" withValue:entity];
        if (person) {
            NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"https://my.jive.com", person.picture]];
            
            UIImageView * iv = [[UIImageView alloc] init];
            CGRect frame;
            switch (count) {
                case 0:
                    frame = CGRectMake(0, 0, 25, 25);
                    imageUrl = [NSURL URLWithString:@"http://png-3.findicons.com/files/icons/1072/face_avatars/300/i02.png"];
                    break;
                case 1:
                    frame = CGRectMake(25, 0, 25, 25);
                    imageUrl = [NSURL URLWithString:@"http://png-5.findicons.com/files/icons/1072/face_avatars/300/n02.png"];
                    break;
                case 2:
                    frame = CGRectMake(0, 25, 25, 25);
                    imageUrl = [NSURL URLWithString:@"http://png-1.findicons.com/files/icons/1072/face_avatars/300/g01.png"];
                    break;
                case 3:
                    frame = CGRectMake(25, 25, 25, 25);
                    break;
                    
                default:
                    break;
            }
            iv.frame = frame;
            
            if (count == 3) {
                UIView * groupCount = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
                groupCount.backgroundColor = [UIColor colorWithRed:0.043 green:0.455 blue:0.808 alpha:1];
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
                label.textColor = [UIColor whiteColor];
                label.text = [NSString stringWithFormat:@"+%i", entities.count - 4];
                label.center = groupCount.center;
                label.font = [UIFont italicSystemFontOfSize:14.0f];
                
                [groupCount addSubview:label];
                
                UIImage *countImage = [Common imageFromView:groupCount];
                [iv setImage:countImage];
            }
            else {
                [iv setImageWithURL:imageUrl];
            }
            
            iv.bounds = CGRectInset(iv.frame, 2, 2);
            
            [self.conversationThumbnailView addSubview:iv];
            
            count++;
            if (count > 3) {
                break;
            }
        }
    }
}

@end
