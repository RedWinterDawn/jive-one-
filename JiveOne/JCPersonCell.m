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

- (void)setPerson:(ClientEntities *)person
{
    //[self removeObservers];
    if ([person isKindOfClass:[ClientEntities class]]) {
        _person = person;
        
        //check to see if the person is a favorite
        if (person.isFavorite.boolValue == 1) {
            NSMutableString *name = [[NSMutableString alloc]initWithString: person.firstLastName];
            NSString *star = @"  ★";
            NSString *nameAndStarAsAnNSString = [NSString stringWithString:[name stringByAppendingString:star]];
            
            
            UIColor *theRightShadeOfYellowForOurStar = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
            NSRange starLocation = [nameAndStarAsAnNSString rangeOfString:@"★"];
            NSMutableAttributedString *personAttributedName = [[NSMutableAttributedString alloc]initWithString:nameAndStarAsAnNSString];
            [personAttributedName setAttributes:@{NSForegroundColorAttributeName : theRightShadeOfYellowForOurStar} range:starLocation];
            
            self.personNameLabel.attributedText = personAttributedName;
        }else{
            self.personNameLabel.text = person.firstLastName;
        }
        
        
        self.personDetailLabel.text = person.email;
        self.personPresenceView.presenceType = (JCPresenceType)[_person.entityPresence.interactions[@"chat"][@"code"] integerValue];
        [self.personPicture setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
        
        [person addObserver:self forKeyPath:kPresenceKeyPathForClientEntity options:NSKeyValueObservingOptionNew context:NULL];
    }   
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
}

-(void)removeObservers
{
    if (_person)
        [_person removeObserver:self forKeyPath:kPresenceKeyPathForClientEntity];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kPresenceKeyPathForClientEntity]) {
        ClientEntities *person = (ClientEntities *)object;
        self.personPresenceView.presenceType = (JCPresenceType)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
    }
}



@end
