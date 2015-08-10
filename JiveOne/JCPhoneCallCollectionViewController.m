//
//  JCCallCardCollectionViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneCallCollectionViewController.h"
#import "JCPhoneManager.h"
#import "JCCallCardViewCell.h"
#import "JCConferenceCallCard.h"

@implementation JCPhoneCallCollectionViewController

NSString *const kJCCallCardCollectionCurrentCallCellReuseIdentifier = @"CurrentCallCardCell";
NSString *const kJCCallCardCollectionIncomingCallCellReuseIdentifier = @"IncomingCallCardCell";
NSString *const kJCCallCardCollectionConferenceCallCellReuseIdentifier = @"ConferenceCallCardCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle mainBundle];
    [self.collectionView registerNib:[UINib nibWithNibName:@"CurrentCallViewCell" bundle:bundle] forCellWithReuseIdentifier:kJCCallCardCollectionCurrentCallCellReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"IncomingCallViewCell" bundle:bundle] forCellWithReuseIdentifier:kJCCallCardCollectionIncomingCallCellReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"ConferenceCallViewCell" bundle:bundle] forCellWithReuseIdentifier:kJCCallCardCollectionConferenceCallCellReuseIdentifier];
}

#pragma mark - Priviate -

-(NSUInteger)numberOfCallsForSection:(NSUInteger)section
{
    return [JCPhoneManager sharedManager].calls.count;
}

-(JCCallCard *)callCardForIndexPath:(NSIndexPath *)indexPath
{
    return [[JCPhoneManager sharedManager].calls objectAtIndex:indexPath.row];
}

#pragma mark - Delegate Handlers -

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self numberOfCallsForSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JCCallCardViewCell *cell;
    JCCallCard *callCard = [self callCardForIndexPath:indexPath];
    if (callCard.lineSession.isIncoming)
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionIncomingCallCellReuseIdentifier forIndexPath:indexPath];
    else if([callCard isKindOfClass:[JCConferenceCallCard class]])
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionConferenceCallCellReuseIdentifier forIndexPath:indexPath];
    else
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionCurrentCallCellReuseIdentifier forIndexPath:indexPath];
    cell.callCard = callCard;
    return cell;
}

@end
