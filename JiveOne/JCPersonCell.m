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
        
        // Set person's image based on whether they actually have one or not
        [self setPersonImage];
        //[self.personPicture setImageWithURL:[NSURL URLWithString:person.picture] placeholderImage:[UIImage imageNamed:@"avatar.png"]];
        
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
                        return (int)[person.entityPresence.interactions[@"chat"][@"code"] integerValue];
                    }
                }
            }
        }
    }
    
    return 0;
}

- (void)setPersonImage
{
    
    
    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kOsgiBaseURL, self.person.picture]];
    NSRange range = [[imageUrl description] rangeOfString:@"avatar"];
    if (range.location == NSNotFound) {
        [self.personPicture setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"avatar.png"]];
    }
    else {
        
        NSString *key = [NSString stringWithFormat:@"%@%@", [self.person.firstName substringToIndex:1], [self.person.lastName substringToIndex:1]];
        
        UIImage *initialsImage = [[JCPersonCell cachedPresenceImages] objectForKey:key];
        if (!initialsImage) {
            UIView * groupCount = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
            groupCount.backgroundColor = [UIColor colorWithRed:0.240 green:0.242 blue:0.242 alpha:.2];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
            label.textColor = [UIColor whiteColor];
            label.text = [NSString stringWithFormat:@"%@%@", [self.person.firstName substringToIndex:1], [self.person.lastName substringToIndex:1]];
            [label sizeToFit];
            label.font = [UIFont boldSystemFontOfSize:12.0f];
            label.center = groupCount.center;
            label.bounds = CGRectInset(label.frame, 2.5f, 0);
            [groupCount addSubview:label];
            
            initialsImage = [Common imageFromView:groupCount];
            [[JCPersonCell cachedPresenceImages] setObject:initialsImage forKey:key];
        }
        else {
            NSLog(@"Cache hit for key: %@", key);
        }
        
        //[iv setImage:countImage];
        
        [self.personPicture setImage:initialsImage];
    }
}

/**
* Image Cache
*
* As images are created, the are added to the image cache. We have a static
* mutable array that is shared by all instaces of the initialsImage. We use the
* dispatch once to ensure that it is only ever instanced once.
*/
+ (NSMutableDictionary *)cachedPresenceImages {
  static NSMutableDictionary *cachedPresenceImages = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
      cachedPresenceImages = [NSMutableDictionary new];
  });
  return cachedPresenceImages;
}


@end
