//
//  JCCallCardCollectionViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionViewController.h"
#import "JCPhoneManager.h"
#import "JCCallCardViewCell.h"

#import "JCConferenceCallCard.h"

@implementation JCCallCardCollectionViewController

NSString *const kJCCallCardCollectionCurrentCallCellReuseIdentifier = @"CurrentCallCardCell";
NSString *const kJCCallCardCollectionIncomingCallCellReuseIdentifier = @"IncomingCallCardCell";
NSString *const kJCCallCardCollectionConferenceCallCellReuseIdentifier = @"ConferenceCallCardCell";

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        JCPhoneManager *phoneManager = [JCPhoneManager sharedManager];
        
        [center addObserver:self selector:@selector(addedCall:) name:kJCPhoneManagerAddedCallNotification object:phoneManager];
        [center addObserver:self selector:@selector(removedCall:) name:kJCPhoneManagerRemoveCallNotification object:phoneManager];
        [center addObserver:self selector:@selector(updateCall:) name:kJCPhoneManagerAnswerCallNotification object:phoneManager];
        
        [center addObserver:self selector:@selector(addedConferenceCallNotification:) name:kJCPhoneManagerAddedConferenceCallNotification object:phoneManager];
        [center addObserver:self selector:@selector(removeConferenceCallNotification:) name:kJCPhoneManagerRemoveConferenceCallNotification object:phoneManager];
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

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)addedCall:(NSNotification *)notification
{
    /*NSDictionary *userInfo = notification.userInfo;
    int count = [[userInfo objectForKey:kJCCallCardManagerPriorUpdateCount] intValue];
    if (count < 1)
        return;
    
    // We only care about animating the add call where out count is > 0 items. If we already have a call, we are showing
    // the collection, so we animate the insertion of a row at the provided index.
    NSNumber *index = [userInfo objectForKey:kJCCallCardManagerUpdatedIndex];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    __unsafe_unretained UICollectionView *collectionView = self.collectionView;
    [collectionView performBatchUpdates:^{
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
    } completion:nil];*/
    
    [self.collectionView reloadData];
}

-(void)updateCall:(NSNotification *)notification
{
    // When we transition a call from an incoming call to a current call the update gets triggered, and we reload the
    // cell the coresponds to the index of that call that was answered.
    /*NSDictionary *userInfo = notification.userInfo;
    NSInteger index = [[userInfo objectForKey:kJCCallCardManagerUpdatedIndex] integerValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    __unsafe_unretained UICollectionView *collectionView = self.collectionView;
    [collectionView performBatchUpdates:^{
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } completion:nil];*/
    
    [self.collectionView reloadData];
}

-(void)removedCall:(NSNotification *)notification
{
    /*NSDictionary *userInfo = notification.userInfo;
    int count = [[userInfo objectForKey:kJCCallCardManagerUpdateCount] intValue];
    if (count < 1)
        return;
    
    NSInteger index = [[userInfo objectForKey:kJCCallCardManagerUpdatedIndex] integerValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    __unsafe_unretained UICollectionView *collectionView = self.collectionView;
    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:nil];*/
    
    
    
    [self.collectionView reloadData];
}

-(void)addedConferenceCallNotification:(NSNotification *)notification
{
    __unsafe_unretained UICollectionView *collectionView = self.collectionView;
    [UIView transitionWithView:self.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        [collectionView reloadData];
                    } completion:^(BOOL finished) {
                        
                    }];
}

-(void)removeConferenceCallNotification:(NSNotification *)notification
{
    __unsafe_unretained UICollectionView *collectionView = self.collectionView;
    [UIView transitionWithView:self.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [collectionView reloadData];
                    } completion:^(BOOL finished) {
                        
                    }];
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
    if (callCard.lineSession.isIncomming)
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionIncomingCallCellReuseIdentifier forIndexPath:indexPath];
    else if([callCard isKindOfClass:[JCConferenceCallCard class]])
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionConferenceCallCellReuseIdentifier forIndexPath:indexPath];
    else
        cell = (JCCallCardViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kJCCallCardCollectionCurrentCallCellReuseIdentifier forIndexPath:indexPath];
    cell.callCard = callCard;
    return cell;
}

@end
