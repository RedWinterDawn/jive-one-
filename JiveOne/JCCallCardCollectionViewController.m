//
//  JCCallCardCollectionViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionViewController.h"
#import "JCCallCardManager.h"
#import "JCCallCardCollectionViewCell.h"

@implementation JCCallCardCollectionViewController

static NSString *const currenctCallCardCellReuseIdentifier = @"CurrentCallCardCell";
static NSString *const incomingCallCardCellReuseIdentifier = @"IncomingCallCardCell";

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle mainBundle];
    [self.collectionView registerNib:[UINib nibWithNibName:@"CurrentCallViewCell" bundle:bundle] forCellWithReuseIdentifier:currenctCallCardCellReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"IncomingCallViewCell" bundle:bundle] forCellWithReuseIdentifier:incomingCallCardCellReuseIdentifier];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.collectionViewLayout performSelector:@selector(invalidateLayout) withObject:nil afterDelay:0];
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
        [self.collectionView reloadData];
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
        [self.collectionView reloadData];
        return;
    }
    
    NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    JCCallCardCollectionViewCell *cell = (JCCallCardCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.3
                     animations:^{
                         cell.alpha = 0;
                         cell.center = CGPointMake(cell.center.x * 10, cell.center.y);
                     }
                     completion:^(BOOL finished) {
                         [self.collectionView performBatchUpdates:^{
                             [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                         } completion:nil];
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
    JCCallCardCollectionViewCell *cell;
    JCCallCard *callCard = [self callCardForIndexPath:indexPath];
    if (callCard.isIncoming)
        cell = (JCCallCardCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:incomingCallCardCellReuseIdentifier forIndexPath:indexPath];
    else
        cell = (JCCallCardCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:currenctCallCardCellReuseIdentifier forIndexPath:indexPath];
    cell.callCard = callCard;
    return cell;
}

@end
