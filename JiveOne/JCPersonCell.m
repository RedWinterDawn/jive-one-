//
//  JCPersonCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonCell.h"
#import "JCPresenceView.h"
#import <SDWebImage/UIImageView+WebCache.h>

//NSString *const kCustomCellPersonPresenceTypeKeyPath = @"entityPresence";

@implementation JCPersonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSArray *bundleArray = [[NSBundle mainBundle] loadNibNamed:@"JCPersonCell" owner:self options:nil];
        self = bundleArray[0];

    }
    return self;
}

- (void)setPerson:(PersonEntities *)person
{
    //[self removeObservers];
    if ([person isKindOfClass:[PersonEntities class]]) {
        _person = person;
                
        self.personNameLabel.text = person.firstLastName;
        self.personDetailLabel.text = person.email;
        self.personPresenceView.presenceType = (JCPresenceType)[_person.entityPresence.interactions[@"chat"][@"code"] integerValue];
        [self.personPicture setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
        
        [person addObserver:self forKeyPath:kPresenceKeyPathForClientEntity options:NSKeyValueObservingOptionNew context:NULL];
    }   
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
}

- (void)removeObservers
{
    if (_person)
        [_person removeObserver:self forKeyPath:kPresenceKeyPathForClientEntity];
}

- (void)dealloc
{
    [self removeObservers];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kPresenceKeyPathForClientEntity]) {
        PersonEntities *person = (PersonEntities *)object;
        self.personPresenceView.presenceType = [self extractPresenceType:person];
    }
}

- (JCPresenceType)extractPresenceType:(PersonEntities *)person
{
    if (person) {
        if (person.entityPresence) {
            if (person.entityPresence.interactions) {
                if (person.entityPresence.interactions[@"chat"]) {
                    if (person.entityPresence.interactions[@"chat"][@"code"]) {
                        return [person.entityPresence.interactions[@"chat"][@"code"] integerValue];
                    }
                }
            }
        }
    }
    
    return 0;
}



@end
