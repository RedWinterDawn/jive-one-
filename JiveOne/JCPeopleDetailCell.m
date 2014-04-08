//
//  JCPeopleDetailCell.m
//  JiveOne
//
//  Created by Doug Leonard on 4/7/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPeopleDetailCell.h"

@implementation JCPeopleDetailCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSArray *bundleArray = [[NSBundle mainBundle] loadNibNamed:@"JCPeopleDetailCell" owner:self options:nil];
        self = bundleArray[0];
        
        UIColor *theRightShadeOfYellowForOurStar = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
        UIColor *starColorForNotSelectedState = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];

        NSMutableAttributedString *attributedStarSelectedState = [[NSMutableAttributedString alloc]initWithString:@"★" attributes:@{NSForegroundColorAttributeName : theRightShadeOfYellowForOurStar}];
        
        
        [self.favoriteButton setAttributedTitle:attributedStarSelectedState forState:UIControlStateSelected];
        
        
        
        
    }
    return self;
}

- (void)setPerson:(ClientEntities *)person
{
    if ([person isKindOfClass:[ClientEntities class]]) {
        _person = person;
        
        self.NameLabel.text = person.firstLastName;
        self.presenceView.presenceType = (JCPresenceType)[_person.entityPresence.interactions[@"chat"][@"code"] integerValue];
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
        self.presenceView.presenceType = (JCPresenceType)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
    }
}



- (IBAction)toggleIsFavorite:(id)sender {
    self.person.isFavorite = @(self.person.isFavorite.boolValue);
    if (self.person.isFavorite.boolValue) {
        
        //TODO:write to core data if the state has changed. account for when directory gets updated and potentially overwritten.
        
        
        
    }else{
        
    }
}
@end
