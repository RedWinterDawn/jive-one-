//
//  JCCallCardCollectionViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionViewController.h"
#import "JCCallCardManager.h"
#import "JCCallCardViewCell.h"

@implementation JCCallCardCollectionViewController

NSString *const kJCCallCardCollectionCurrentCallCellReuseIdentifier = @"CurrentCallCardCell";
NSString *const kJCCallCardCollectionIncomingCallCellReuseIdentifier = @"IncomingCallCardCell";
NSString *const kJCCallCardCollectionConferenceCallCellReuseIdentifier = @"ConferenceCallCardCell";

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        JCCallCardManager *callCardManager = [JCCallCardManager sharedManager];
        
        [center addObserver:self selector:@selector(addedCallCardNotification:) name:kJCCallCardManagerAddedIncomingCallNotification object:callCardManager];
        [center addObserver:self selector:@selector(callCardRemovedNotification:) name:kJCCallCardManagerRemoveIncomingCallNotification object:callCardManager];
        [center addObserver:self selector:@selector(addedCallCardNotification:) name:kJCCallCardManagerAddedCurrentCallNotification object:callCardManager];
        [center addObserver:self selector:@selector(callCardRemovedNotification:) name:kJCCallCardManagerRemoveCurrentCallNotification object:callCardManager];
        
        [center addObserver:self selector:@selector(addedConferenceCallNotification:) name:kJCCallCardManagerAddedConferenceCallNotification object:callCardManager];
        [center addObserver:self selector:@selector(removeConferenceCallNotification:) name:kJCCallCardManagerRemoveConferenceCallNotification object:callCardManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle mainBundle];
    [self.collectionView registerNib:[UINib nibWithNibName:@"CurrentCallViewCell" bundle:bundle] forCellWithReuseIdentifier:kJCCallCardCollectionCurrentCallCellReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"IncomingCallViewCell" bundle:bundle] forCellWithReuseIdentifier:kJCCallCardCollectionIncomingCallCellReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"ConferenceCallViewCell" bundle:bundle] forCellWithReuseIdentifier:kJCCallCardCollectionConferenceCallCellReuseIdentifier];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self performSelector:@selector(refreshLayout) withObject:nil afterDelay:0];
}

-(void)refreshLayout
{
    if (self.collectionViewLayout) {
        [self.collectionViewLayout invalidateLayout];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)addedCallCardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *priorCount = [userInfo objectForKey:kJCCallCardManagerPriorUpdateCount];
    if (priorCount.intValue < 1)
    {
        return;
    }
    
    NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    } completion:nil];
}

-(void)callCardRemovedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *count = [userInfo objectForKey:kJCCallCardManagerUpdateCount];
    if (count.intValue < 1)
    {
        return;
    }
    
    NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:nil];
}

-(void)addedConferenceCallNotification:(NSNotification *)notification
{
    [UIView transitionWithView:self.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        [self.collectionView reloadData];
                    } completion:^(BOOL finished) {
                        
                    }];
}

-(void)removeConferenceCallNotification:(NSNotification *)notification
{
   [UIView transitionWithView:self.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [self.collectionView reloadData];
                    } completion:^(BOOL finished) {
                        
                    }];
}

#pragma mark - Priviate -

-(NSUInteger)numberOfCallsForSection:(NSUInteger)section
{
    return [JCCallCardManager sharedManager].calls.count;
}

-(JCCallCard *)callCardForIndexPath:(NSIndexPath *)indexPath
{
    return [[JCCallCardManager sharedManager].calls objectAtIndex:indexPath.row];
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
    if (callCard.isIncoming)
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionIncomingCallCellReuseIdentifier forIndexPath:indexPath];
    else if(callCard.isConference)
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionConferenceCallCellReuseIdentifier forIndexPath:indexPath];
    else
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionCurrentCallCellReuseIdentifier forIndexPath:indexPath];
    cell.callCard = callCard;
    return cell;
}

@end
