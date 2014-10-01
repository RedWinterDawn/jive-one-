//
//  JCCallCardCollectionViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionViewController.h"

@interface JCCallCardCollectionViewController ()
{
    NSMutableArray *_calls;
    NSMutableArray *_incomingCalls;
}

@end

@implementation JCCallCardCollectionViewController

static NSString * const currenctCallCardCellReuseIdentifier = @"CurrentCallCardCell";
static NSString * const incommingCallCardCellReuseIdentifier = @"IncommingCallCardCell";

-(void)addCall:(NSString *)callIdentifier
{
    if (!_calls)
        _calls = [NSMutableArray array];
    
    if ([_calls containsObject:callIdentifier])
        return;
        
    [_calls addObject:callIdentifier];
    [self.collectionView reloadData];
}

-(void)removeCall:(NSString *)callIdentifier
{
    if (!_calls)
        return;
    
    if (![_calls containsObject:callIdentifier])
        return;
    
    [_calls removeObject:callIdentifier];
    [self.collectionView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0)
        return (_incomingCalls) ? _incomingCalls.count : 0;
    return (_calls) ? _calls.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = nil;
    NSString *identifier = nil;
    if (indexPath.section == 0)
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:incommingCallCardCellReuseIdentifier forIndexPath:indexPath];
        identifier = [_incomingCalls objectAtIndex:indexPath.row];
    }
    else
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:currenctCallCardCellReuseIdentifier forIndexPath:indexPath];
        identifier = [_calls objectAtIndex:indexPath.row];
    }
    [_delegate callCardCollectionViewController:self configureCell:cell callIdentifier:identifier];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(304, 200);
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
