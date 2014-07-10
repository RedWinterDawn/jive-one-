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
#import "Common.h"
#import "LineGroup.h"
#import "ContactGroup.h"
#import "PBX+Custom.h"

//NSString *const kCustomCellPersonPresenceTypeKeyPath = @"entityPresence";
@interface JCPersonCell ()
@property (nonatomic) NSManagedObjectContext* managedContext;
@end
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

- (NSManagedObjectContext*)managedContext
{
    if (!_managedContext) {
        _managedContext = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    return _managedContext;
}

- (void)awakeFromNib
{
    // Initialization code
    [self bringSubviewToFront:self.favoriteBut];
}


- (void)setPerson:(PersonEntities *)person
{
    if ([person isKindOfClass:[Lines class]])
        {
            Lines *line = (Lines *)person;
            _line = line;
            [self.personNameLabel setNumberOfLines:0];
            self.personNameLabel.text = line.displayName;
            [self.personNameLabel sizeToFit];
            [self configureFavoriteStatus];
            self.personDetailLabel.text = line.externsionNumber;
            self.personPresenceView.presenceType = (JCPresenceType) [line.state integerValue];
            [line addObserver:self forKeyPath:kPresenceKeyPathForLineEntity options:NSKeyValueObservingOptionNew context:NULL];
        }
    
}

- (void)configureFavoriteStatus
{
    //selected star should be yellow unselected star should be gray
    UIColor *selectedStarColor = [UIColor colorWithRed:255.0/255.0 green:212.0/255.0 blue:0.0/255.0 alpha:1.0];
    NSMutableAttributedString *selectedAttributedStarSelectedState = [[NSMutableAttributedString alloc]initWithString:@"★" attributes:@{NSForegroundColorAttributeName : selectedStarColor}];
    UIColor *unselectedStarColor = [UIColor colorWithRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0];
    
    NSMutableAttributedString *unselectedAttributedStarSelectedState = [[NSMutableAttributedString alloc]initWithString:@"★" attributes:@{NSForegroundColorAttributeName : unselectedStarColor}];
    [self.favoriteBut setAttributedTitle:selectedAttributedStarSelectedState forState:UIControlStateSelected];
    [self.favoriteBut setAttributedTitle:unselectedAttributedStarSelectedState forState:UIControlStateNormal];
    
    if ([self.line.isFavorite  isEqual: @1]) {
        [self.favoriteBut setSelected:YES];
    }else{
        [self.favoriteBut setSelected:NO];
    }
    else if ([person isKindOfClass:[Lines class]])
    {
        Lines *line = (Lines *)person;
        _line = line;
        [self.personNameLabel setNumberOfLines:0];
        self.personNameLabel.text = line.displayName;
        [self.personNameLabel sizeToFit];
        //[self configureFavoriteStatus];
		
		NSString * detailText = line.externsionNumber;
		PBX *pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:line.pbxId];
		if (pbx) {
			NSString *name = pbx.name;
			if (![Common stringIsNilOrEmpty:name]) {
				detailText = [NSString stringWithFormat:@"%@ on %@", line.externsionNumber, name];
			}
			else {
				detailText = [NSString stringWithFormat:@"%@", line.externsionNumber];
			}
		}
		else {
			detailText = [NSString stringWithFormat:@"%@", line.externsionNumber];
		}
        
        
        self.personDetailLabel.text = detailText;
		
		
        self.personPresenceView.presenceType = (JCPresenceType) [line.state integerValue]; //JCPresenceTypeAvailable;// (JCPresenceType)[_person.entityPresence.interactions[@"chat"][@"code"] integerValue];
        
        // Set person's image based on whether they actually have one or not
        //[self setPersonImage];
        //[self.personPicture setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
        
		[self updateFavoriteIcon:self];
        [line addObserver:self forKeyPath:kPresenceKeyPathForLineEntity options:NSKeyValueObservingOptionNew context:NULL];

        
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
}

- (void)removeObservers
{
    if (_line)
        [_line removeObserver:self forKeyPath:kPresenceKeyPathForLineEntity];
}

- (void)dealloc
{
    [self removeObservers];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kPresenceKeyPathForLineEntity]) {
        Lines *line = (Lines *)object;
        self.personPresenceView.presenceType = (JCPresenceType)[line.state integerValue];
    }
}

- (JCPresenceType)extractPresenceType:(PersonEntities *)person
{
    if (person) {
        if (person.entityPresence) {
            if (person.entityPresence.interactions) {
                if (person.entityPresence.interactions[@"chat"]) {
                    if (person.entityPresence.interactions[@"chat"][@"code"]) {
                        return (int)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
                    }
                }
            }
        }
    }
    
    return 0;
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

-(void)updateTableViewCell:(JCPersonCell*)cell
{
    [self.delegate updateTableViewCell:cell];
}

- (IBAction)toggleFavoriteStatus:(id)sender {
    
	_managedContext = [self managedContext];
		
    if ([self.line.isFavorite  isEqual: @1]) {
        self.line.isFavorite = @0;
        [self.favoriteBut setSelected:NO];
    }else{
        self.line.isFavorite = @1;
        [self.favoriteBut setSelected:YES];
    }
    NSLog(@"self.line.isFavorite:%@",self.line.isFavorite);
    
    [self groupRelationshipStuff];
    [_managedContext MR_saveToPersistentStoreAndWait];
    [self updateTableViewCell:self];
}

- (void)groupRelationshipStuff
{
	ContactGroup *group = [ContactGroup MR_findFirstByAttribute:@"groupName" withValue:@"Favorites"];
	if (!group) {
		group = [ContactGroup MR_createInContext:_managedContext];
		group.groupId = [[NSUUID UUID] UUIDString];
		group.groupName = @"Favorites";
	}
    
	// create relationship
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(groupId == %@) AND (lineId == %@)", group.groupId, self.line.jrn];
	LineGroup *lg = [LineGroup MR_findFirstWithPredicate:pred];
	if (!lg && [self.line.isFavorite boolValue]) {
		lg = [LineGroup MR_createInContext:_managedContext];
		lg.lineId = self.line.jrn;
		lg.groupId = group.groupId;
	}
	else  if (lg && ![self.line.isFavorite boolValue])
	{
		[lg MR_deleteEntity];
	}
}

@end



//- (void)setPersonImage
//{

    
    //    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kOsgiBaseURL, self.person.picture]];
    //    NSRange range = [[imageUrl description] rangeOfString:@"avatar"];
    //    if (range.location == NSNotFound) {
    //        [self.personPicture setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"avatar.png"]];
    //    }
    //    else {
    //
    //        NSString *firstInitial = @"";
    //        NSString *secondInitial = @"";
    //
    //        if (self.person.firstName && [self.person.firstName length] > 0) {
    //            firstInitial = [self.person.firstName substringToIndex:1];
    //        }
    //        else {
    //            [self.personPicture setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"avatar.png"]];
    //            return;
    //        }
    //
    //        if (self.person.lastName && [self.person.lastName length] > 0) {
    //            secondInitial = [self.person.lastName substringToIndex:1];
    //        }
    //        else {
    //            [self.personPicture setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"avatar.png"]];
    //            return;
    //        }
    //
    //        NSString *key = [NSString stringWithFormat:@"%@%@", firstInitial, secondInitial];
    //
    //        UIImage *initialsImage = [[JCPersonCell chachedInitialsImages] objectForKey:key];
    //        if (!initialsImage) {
    //            UIView * groupCount = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    //            groupCount.backgroundColor = [UIColor colorWithRed:0.847 green:0.871 blue:0.882 alpha:1] /*#d8dee1*/;
    //
    //            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
    //            label.textColor = [UIColor whiteColor];
    //
    //            label.text = [NSString stringWithFormat:@"%@%@", firstInitial, secondInitial];
    //            [label sizeToFit];
    //            label.font = [UIFont boldSystemFontOfSize:12.0f];
    //            label.center = groupCount.center;
    //            label.bounds = CGRectInset(label.frame, 2.5f, 0);
    //            [groupCount addSubview:label];
    //
    //            initialsImage = [Common imageFromView:groupCount];
    //            [[JCPersonCell chachedInitialsImages] setObject:initialsImage forKey:key];
    //        }
    //        else {
    ////            NSLog(@"Cache hit for key: %@", key);
    //        }
    //
    //        [self.personPicture setImage:initialsImage];
    //    }
//}
