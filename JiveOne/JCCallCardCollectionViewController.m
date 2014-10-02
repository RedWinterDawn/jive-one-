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
    
    [center addObserver:self selector:@selector(addedIncomingCallCardNotification:) name:kJCCallCardManagerAddedIncomingCallNotification object:callCardManager];
    [center addObserver:self selector:@selector(incomingCallCardRemovedNotification:) name:kJCCallCardManagerRemoveIncomingCallNotification object:callCardManager];
    [center addObserver:self selector:@selector(addedCurrentCallCardNotification:) name:kJCCallCardManagerAddedCurrentCallNotification object:callCardManager];
    [center addObserver:self selector:@selector(currentCallCardRemovedNotification:) name:kJCCallCardManagerRemoveCurrentCallNotification object:callCardManager];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)addedIncomingCallCardNotification:(NSNotification *)notification
{
    /*NSDictionary *userInfo = notification.userInfo;
     NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
     NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:1];
     //[self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
     //[self.collectionView insertItemsAtIndexPaths:@[indexPath]];*/
    
    
    // For now reload the whole table....will change to handle animated entry and exit.
    [self.collectionView reloadData];
    
}

-(void)incomingCallCardRemovedNotification:(NSNotification *)notification
{
    /*NSDictionary *userInfo = notification.userInfo;
     NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
     NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:1];*/
    
    // For now reload the whole table....will change to handle animated entry and exit.
    [self.collectionView reloadData];
}

-(void)addedCurrentCallCardNotification:(NSNotification *)notification
{
    /*NSDictionary *userInfo = notification.userInfo;
    NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:1];
    //[self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    //[self.collectionView insertItemsAtIndexPaths:@[indexPath]];*/
    
    
    // For now reload the whole table....will change to handle animated entry and exit.
    [self.collectionView reloadData];
    
}

-(void)currentCallCardRemovedNotification:(NSNotification *)notification
{
    /*NSDictionary *userInfo = notification.userInfo;
    NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:1];*/
    
    // For now reload the whole table....will change to handle animated entry and exit.
    [self.collectionView reloadData];
}

#pragma mark - Priviate -

-(NSUInteger)numberOfCallsForSection:(NSUInteger)section
{
    JCCallCardManager *callManager = [JCCallCardManager sharedManager];
    if (section == 0)
        return (callManager.incomingCalls) ? callManager.incomingCalls.count : 0;
    return (callManager.currentCalls) ? callManager.currentCalls.count : 0;
}

-(JCCallCard *)callCardForIndexPath:(NSIndexPath *)indexPath
{
    JCCallCardManager *callManager = [JCCallCardManager sharedManager];
    if (indexPath.section == 0)
        return [callManager.incomingCalls objectAtIndex:indexPath.row];
    return [callManager.currentCalls objectAtIndex:indexPath.row];
}

#pragma mark - Delegate Handlers -

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self numberOfCallsForSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JCCallCardCollectionViewCell *cell = nil;
    if (indexPath.section == 0)
        cell = (JCCallCardCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:incommingCallCardCellReuseIdentifier forIndexPath:indexPath];
    else
        cell = (JCCallCardCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:currenctCallCardCellReuseIdentifier forIndexPath:indexPath];
    cell.callCard = [self callCardForIndexPath:indexPath];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger calls = [JCCallCardManager sharedManager].totalCalls;
    if (calls == 1)
        return self.view.bounds.size;
    
    if(calls == 2)
        return CGSizeMake(self.view.bounds.size.width, (self.view.bounds.size.height - 10) / 2 );
    
    return CGSizeMake(self.view.bounds.size.width, 150);
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
