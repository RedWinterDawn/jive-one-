//
//  JCPersonCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonCell.h"

//NSString *const kCustomCellPersonPresenceTypeKeyPath = @"entityPresence";
@interface JCPersonCell ()

@end

@implementation JCPersonCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    Person *person = self.person;
    self.personNameLabel.text = person.name;
    self.personDetailLabel.text = person.detailText;
    
    //self.personPresenceView.presenceType = (JCPresenceType) [line.state integerValue];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    if ([keyPath isEqualToString:kPresenceKeyPathForLineEntity]) {
//        Line *line = (Line *)object;
//        self.personPresenceView.presenceType = (JCPresenceType)[line.state integerValue];
//    }
}

//- (void)prepareForReuse
//{
//    [super prepareForReuse];
//    [self removeObservers];
//}
//
//- (void)dealloc
//{
//    [self removeObservers];
//}

#pragma mark - Setters -

//-(void)setLine:(Line *)line
//{
//    if ([line isKindOfClass:[Line class]])
//    {
//        _line = line;
//        [line addObserver:self forKeyPath:kPresenceKeyPathForLineEntity options:NSKeyValueObservingOptionNew context:NULL];
//    }
//}

#pragma mark - Private -

//- (void)removeObservers
//{
//    if (_line)
//        [_line removeObserver:self forKeyPath:kPresenceKeyPathForLineEntity];
//}



/*- (void)createGroupRelationship
{
	ContactGroup *group = [ContactGroup MR_findFirstByAttribute:@"groupName" withValue:@"Favorites"];
	if (!group) {
		group = [ContactGroup MR_createInContext:self.line.managedObjectContext];
		group.groupId = [[NSUUID UUID] UUIDString];
		group.groupName = @"Favorites";
	}
    
	// create relationship
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(groupId == %@) AND (lineId == %@)", group.groupId, self.line.jrn];
	LineGroup *lg = [LineGroup MR_findFirstWithPredicate:pred];
	if (!lg && [self.line.isFavorite boolValue]) {
		lg = [LineGroup MR_createInContext:self.line.managedObjectContext];
		lg.lineId = self.line.jrn;
		lg.groupId = group.groupId;
	}
	else  if (lg && ![self.line.isFavorite boolValue])
	{
		[lg MR_deleteEntity];
	}
}*/

@end



/**
 * Image Cache
 *
 * As images are created, the are added to the image cache. We have a static
 * mutable array that is shared by all instaces of the initialsImage. We use the
 * dispatch once to ensure that it is only ever instanced once.
 */
/*+ (NSMutableDictionary *)chachedInitialsImages {
    static NSMutableDictionary *cachedPresenceImages = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        cachedPresenceImages = [NSMutableDictionary new];
    });
    return cachedPresenceImages;
}*/


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
