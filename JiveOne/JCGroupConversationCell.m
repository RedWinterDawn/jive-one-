//
//  JCGroupConvoTableViewCell.m
//  JiveOne
//
//  Created by Doug Leonard on 4/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCGroupConversationCell.h"
#import "ConversationEntry+Custom.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Common.h"
#import "Constants.h"

@implementation JCGroupConversationCell

- (void)awakeFromNib
{
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSArray *bundleArray = [[NSBundle mainBundle] loadNibNamed:@"JCGroupConversationCell" owner:self options:nil];
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
        if (person) {
            _person = person;
            // add observer to the person presence, even if it's a group, just so our app don't break.
            [_person addObserver:self forKeyPath:kPresenceKeyPathForClientEntity options:NSKeyValueObservingOptionNew context:NULL];
            
            // set cell title
            if ([_conversation.isGroup boolValue]) {
                self.conversationTitle.text = _conversation.name;
                
                [self createComposedImageForGroup];
            }
            else {
                self.conversationTitle.text = person.firstLastName;
                
                
                
                UIImageView *singleImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                [singleImage setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                [self.conversationThumbnailView addSubview:singleImage];
                //[self.conversationImage setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
            }
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
                NSNumber *number = [badges objectForKey:_conversation.conversationId];
                if (number.integerValue != 0) {
                    _conversationUnseenMessages.hidden = NO;
                    _conversationUnseenMessages.text = number.stringValue;
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
    }
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [[self.conversationThumbnailView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
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
    NSString *delete_button_name = @"vm-delete.png";
    for (UIView *subview in subviews)
    {
        //handles ios6 and earlier
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"])
        {
            //we'll add a view to cover the default control as the image used has a transparent BG
            UIView *backgroundCoverDefaultControl = [[UIView alloc] initWithFrame:CGRectMake(0,0, 64, 33)];
            [backgroundCoverDefaultControl setBackgroundColor:[UIColor whiteColor]];//assuming your view has a white BG
            [[subview.subviews objectAtIndex:0] addSubview:backgroundCoverDefaultControl];
            UIImage *deleteImage = [UIImage imageNamed:delete_button_name];
            UIImageView *deleteBtn = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0,deleteImage.size.width, deleteImage.size.height)];
            [deleteBtn setImage:[UIImage imageNamed:delete_button_name]];
            [[subview.subviews objectAtIndex:0] addSubview:deleteBtn];
        }
        //the rest handles ios7
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationButton"])
        {
            UIButton *deleteButton = (UIButton *)subview;
            [deleteButton setImage:[UIImage imageNamed:delete_button_name] forState:UIControlStateNormal];
            [deleteButton setTitle:@"" forState:UIControlStateNormal];
            [deleteButton setBackgroundColor:[UIColor redColor]];
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
}



- (void)createComposedImageForGroup
{
    NSArray *entities = (NSArray *)self.conversation.entities;
    //int entitiesCount = entities.count;
    int count = 0;
    
    //UIView *compositeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    
    for (NSString* entity in self.conversation.entities) {
        PersonEntities *person = [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:entity];
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
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
                label.textColor = [UIColor whiteColor];
                label.text = [NSString stringWithFormat:@"+%lu", entities.count - 4];
                [label sizeToFit];
                label.font = [UIFont boldSystemFontOfSize:12.0f];
                label.center = groupCount.center;
                label.bounds = CGRectInset(label.frame, 2, 0);
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
