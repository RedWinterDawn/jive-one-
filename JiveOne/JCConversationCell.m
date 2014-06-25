    //
//  JCConversationTableViewCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationCell.h"
#import "ConversationEntry+Custom.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Common.h"
#import "Constants.h"

@implementation JCConversationCell

# define PRESENCE_POSITION CGRectMake(63, 9, 16, 16)

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSArray *bundleArray = [[NSBundle mainBundle] loadNibNamed:@"JCConversationCell" owner:self options:nil];
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
        
        PersonEntities * person = [[JCOmniPresence sharedInstance] entityByEntityId:firstEntity];

        if (!firstEntity && !person) {
            person = [[JCOmniPresence sharedInstance] me];
            //self.conversationTitle.text = person.firstLastName;
        }

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
                
                //[self createComposedImageForGroup];
            }
            else {
                self.conversationTitle.text = person.firstLastName;
                
                 // if it's a person we want to set presence;
                
                self.presenceView.presenceType = (JCPresenceType)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
                
                self.presenceView.hidden = NO;
                
//                [singleImage setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
//                [self.conversationThumbnailView addSubview:singleImage];
                [self setPersonImage];
            }
        }
        else
        {
            
//            else {
                self.conversationTitle.text = NSLocalizedString(@"Unknown", nil);
//            }
            
        }
        
        // set the conversastion time label
        self.conversationTime.text = [Common shortDateFromTimestamp:_conversation.lastModified];
        
        // grab the last entry for the conversation and set in the snippet lable
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"conversationId ==[c] %@", _conversation.conversationId];
        ConversationEntry *lastEntry = [ConversationEntry MR_findFirstWithPredicate:predicate sortedBy:@"lastModified" ascending:NO];
        if (lastEntry) {
            self.conversationSnippet.text = lastEntry.message[@"raw"];
        }
        
        // set unseen messages for conversation
        NSMutableDictionary *badges = (NSMutableDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"];
        if (badges) {
            if ([badges objectForKey:_conversation.conversationId]) {
                NSMutableDictionary *entries = [badges objectForKey:_conversation.conversationId];
                NSLog(@"%@", _conversation.conversationId);
                if ([entries isKindOfClass:[NSDictionary class]] && entries.count != 0) {
                    _conversationUnseenMessages.hidden = NO;
                    _conversationUnseenMessages.text = [NSString stringWithFormat:@"%lu", (unsigned long)entries.count];
                }
                else {
                    _conversationUnseenMessages.hidden = YES;
                }
            }
            else {
                _conversationUnseenMessages.hidden = YES;
            }
        }
        else {
            _conversationUnseenMessages.hidden = YES;
        }
        
        [self adjustTitlePositionPresenceVisibility];
    }
}

- (void) adjustTitlePositionPresenceVisibility
{
    if (self.presenceView.hidden) {
            //Group message styling
        
        
        self.conversationTitle.bounds = CGRectMake((self.conversationTitle.bounds.origin.x - kShiftNameLabelThisMuch),
                                           self.conversationTitle.bounds.origin.y,
                                           self.conversationTitle.bounds.size.width,
                                           self.conversationTitle.bounds.size.height);
//        self.nameLabel.bounds
        //            [self.spinningWheel performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];

    }
    else
    {// chat with one other person styling
        
    }
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [[self.conversationThumbnailView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setNeedsDisplay];
    [self removeObservers];
}

-(void)willTransitionToState:(UITableViewCellStateMask)state{
    NSLog(@"EventTableCell willTransitionToState");
    [super willTransitionToState:state];
    if((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask){
        [self recurseAndReplaceSubViewIfDeleteConfirmationControl:self.subviews];
        [self performSelector:@selector(recurseAndReplaceSubViewIfDeleteConfirmationControl:) withObject:self.subviews afterDelay:0];
    }
}
-(void)recurseAndReplaceSubViewIfDeleteConfirmationControl:(NSArray*)subviews{
   // NSString *delete_button_name = @"";
    for (UIView *subview in subviews)
    {
        //handles ios6 and earlier
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"])
        {
            //we'll add a view to cover the default control as the image used has a transparent BG
            UIView *backgroundCoverDefaultControl = [[UIView alloc] initWithFrame:CGRectMake(0,0, 64, 33)];
            [backgroundCoverDefaultControl setBackgroundColor:[UIColor whiteColor]];//assuming your view has a white BG
            [[subview.subviews objectAtIndex:0] addSubview:backgroundCoverDefaultControl];
//            UIImage *deleteImage = [UIImage imageNamed:delete_button_name];
//            UIImageView *deleteBtn = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0,deleteImage.size.width, deleteImage.size.height)];
//            [deleteBtn setImage:[UIImage imageNamed:delete_button_name]];
//            [[subview.subviews objectAtIndex:0] addSubview:deleteBtn];
        }
        //the rest handles ios7
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationButton"])
        {
//            UIButton *deleteButton = (UIButton *)subview;
//            [deleteButton setImage:[UIImage imageNamed:delete_button_name] forState:UIControlStateNormal];
//            [deleteButton setTitle:@"" forState:UIControlStateNormal];
//            [deleteButton setBackgroundColor:[UIColor redColor]];
            for(UIView* view in subview.subviews){
                if([view isKindOfClass:[UILabel class]]){
                    [view removeFromSuperview];
                }
            }
        }
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationView"])
        {
            for(UIView* innerSubView in subview.subviews){
                if(![innerSubView isKindOfClass:[UIButton class]]){
                    [innerSubView removeFromSuperview];
                }
            }
        }
        if([subview.subviews count]>0){
            [self recurseAndReplaceSubViewIfDeleteConfirmationControl:subview.subviews];
        }
        
    }
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
        PersonEntities *person = (PersonEntities *)object;
        self.presenceView.presenceType = (JCPresenceType)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
    }
}



- (void)setPersonImage
{
    UIImageView *singleImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kOsgiBaseURL, self.person.picture]];
    NSRange range = [[imageUrl description] rangeOfString:@"avatar"];
    if (range.location == NSNotFound) {
        [singleImage setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"avatar.png"]];
        [self.conversationThumbnailView addSubview:singleImage];
    }
    else {
        
        NSString *firstInitial = @"";
        NSString *secondInitial = @"";
        
        if (self.person.firstName && [self.person.firstName length] > 0) {
            firstInitial = [self.person.firstName substringToIndex:1];
        }
        else {
            [singleImage setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"avatar.png"]];
            [self.conversationThumbnailView addSubview:singleImage];
            return;
        }
        
        if (self.person.lastName && [self.person.lastName length] > 0) {
            secondInitial = [self.person.lastName substringToIndex:1];
        }
        else {
            [singleImage setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"avatar.png"]];
            [self.conversationThumbnailView addSubview:singleImage];
            return;
        }
        
        NSString *key = [NSString stringWithFormat:@"%@%@", firstInitial, secondInitial];
        
        UIImage *initialsImage = [[JCConversationCell chachedInitialsImages] objectForKey:key];
        if (!initialsImage) {
            UIView * groupCount = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
            groupCount.backgroundColor = [UIColor colorWithRed:0.847 green:0.871 blue:0.882 alpha:1] /*#d8dee1*/;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
            label.textColor = [UIColor whiteColor];
            
            label.text = [NSString stringWithFormat:@"%@%@", firstInitial, secondInitial];
            [label sizeToFit];
            label.font = [UIFont boldSystemFontOfSize:12.0f];
            label.center = groupCount.center;
            label.bounds = CGRectInset(label.frame, 2.5f, 0);
            [groupCount addSubview:label];
            
            initialsImage = [Common imageFromView:groupCount];
            [[JCConversationCell chachedInitialsImages] setObject:initialsImage forKey:key];
        }
        else {
//            NSLog(@"Cache hit for key: %@", key);
        }
        
        [singleImage setImage:initialsImage];
        [self.conversationThumbnailView addSubview:singleImage];
    }
}

/**
 * Image Cache
 *
 * As images are created, the are added to the image cache. We have a static
 * mutable array that is shared by all instaces of the initialsImage. We use the
 * dispatch once to ensure that it is only ever instanced once.
 */
+ (NSMutableDictionary *)chachedInitialsImages {
    static NSMutableDictionary *cachedPresenceImages = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        cachedPresenceImages = [NSMutableDictionary new];
    });
    return cachedPresenceImages;
}

@end
