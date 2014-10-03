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

static NSString * const currenctCallCardCellReuseIdentifier = @"CurrentCallCardCell";
static NSString * const incommingCallCardCellReuseIdentifier = @"IncommingCallCardCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    JCCallCardManager *callCardManager = [JCCallCardManager sharedManager];
    
    [center addObserver:self selector:@selector(addedCallCardNotification:) name:kJCCallCardManagerAddedIncomingCallNotification object:callCardManager];
    [center addObserver:self selector:@selector(callCardRemovedNotification:) name:kJCCallCardManagerRemoveIncomingCallNotification object:callCardManager];
    [center addObserver:self selector:@selector(addedCallCardNotification:) name:kJCCallCardManagerAddedCurrentCallNotification object:callCardManager];
    [center addObserver:self selector:@selector(callCardRemovedNotification:) name:kJCCallCardManagerRemoveCurrentCallNotification object:callCardManager];
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
    /*if (count.intValue < 1)
    {
        [self.collectionView reloadData];
        return;
    }*/
    
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
    return [JCCallCardManager sharedManager].totalCalls;
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
    JCCallCardCollectionViewCell *cell = nil;
    JCCallCard *callCard = [self callCardForIndexPath:indexPath];
    if (callCard.isIncoming)
        cell = (JCCallCardCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:incommingCallCardCellReuseIdentifier forIndexPath:indexPath];
    else
        cell = (JCCallCardCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:currenctCallCardCellReuseIdentifier forIndexPath:indexPath];
    cell.callCard = callCard;
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
