//
//  JCCallCardCollectionLayout.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionLayout.h"
#import "JCCallCardManager.h"
#import "JCCallCardViewCell.h"

#define MINIMUM_CELL_HEIGHT 180.0f

static NSString * const JSCallCardLayoutCellKind = @"CallCardCell";

@interface JCCallCardCollectionLayout ()

@property (nonatomic, strong) NSMutableArray *deleteIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertIndexPaths;
@property (nonatomic, strong) NSDictionary *layoutInfo;

@property (nonatomic, readonly) CGFloat cellHeight;

@end

@implementation JCCallCardCollectionLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _itemInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 10.0f);
    _interItemSpacingY = 10.0f;
}

#pragma mark - Properties -

-(CGFloat)cellHeight
{
    CGFloat height = self.collectionView.bounds.size.height;
    NSUInteger calls = [JCCallCardManager sharedManager].calls.count;
    if(calls == 2)
        height = ((height - _interItemSpacingY) / 2 );
    else if(calls > 2)
        height = MINIMUM_CELL_HEIGHT;
    return height;
}

#pragma mark - Vertical Layout -

-(void)prepareLayout
{
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    for (NSInteger section = 0; section < sectionCount; section++)
    {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        if (itemCount > 0)
        {
            CGFloat height = self.cellHeight;
            CGFloat width = self.collectionView.bounds.size.width - (_itemInsets.left + _itemInsets.right);
            CGFloat x = _itemInsets.left;
            for (NSInteger item = 0; item < itemCount; item++)
            {
                indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                UICollectionViewLayoutAttributes *itemAttributes =
                [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
                CGFloat y = floor((height + _interItemSpacingY) * indexPath.row);
                itemAttributes.frame = CGRectMake(x, y, width, height);
                cellLayoutInfo[indexPath] = itemAttributes;
            }
        }
    }
    
    newLayoutInfo[JSCallCardLayoutCellKind] = cellLayoutInfo;
    self.layoutInfo = newLayoutInfo;
}

-(CGSize)collectionViewContentSize
{
    NSArray *array = self.layoutInfo[JSCallCardLayoutCellKind];
    NSInteger rowCount = array.count;
    CGFloat height = self.itemInsets.top + (rowCount * self.cellHeight) + (rowCount - 1) * _interItemSpacingY + _itemInsets.bottom;
    
    return CGSizeMake(self.collectionView.bounds.size.width, height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier, NSDictionary *elementsInfo, BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *innerStop) {
            if (CGRectIntersectsRect(rect, attributes.frame))
                [allAttributes addObject:attributes];
        }];
    }];
    return allAttributes;
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[JSCallCardLayoutCellKind][indexPath];
}

#pragma mark - Updates -

-(void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    [super prepareForCollectionViewUpdates:updateItems];
    _deleteIndexPaths = [NSMutableArray array];
    _insertIndexPaths = [NSMutableArray array];
    for (UICollectionViewUpdateItem *update in updateItems)
    {
        if (update.updateAction == UICollectionUpdateActionDelete)
            [_deleteIndexPaths addObject:update.indexPathBeforeUpdate];
        else if (update.updateAction == UICollectionUpdateActionInsert)
            [_insertIndexPaths addObject:update.indexPathAfterUpdate];
    }
}

-(void)finalizeCollectionViewUpdates
{
    [super finalizeCollectionViewUpdates];
    _deleteIndexPaths = nil;
    _insertIndexPaths = nil;
}

-(UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    if ([self.insertIndexPaths containsObject:itemIndexPath])
    {
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        /*JCCallCardViewCell *cell = (JCCallCardViewCell *)[self.collectionView.dataSource collectionView:self.collectionView cellForItemAtIndexPath:itemIndexPath];
        JCCallCard *callCard = cell.callCard;
        if (callCard.isConference)
            return attributes;
        
        if (callCard.isIncoming)
            attributes.center = CGPointMake(attributes.center.x, -attributes.center.y);
        else*/
            attributes.center = CGPointMake(attributes.center.x * 2, attributes.center.y);
        attributes.alpha = 0.0;
    }
    return attributes;
}

-(UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    if ([self.deleteIndexPaths containsObject:itemIndexPath])
    {
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        /*[self.collectionView.viewForBaselineLayout.layer setSpeed:1.5f];
        JCCallCard *callCard = ((JCCallCardViewCell *)[self.collectionView cellForItemAtIndexPath:itemIndexPath]).callCard;
        if (callCard.isConference)
            return attributes;
        
        if (callCard.isIncoming)
            attributes.center = CGPointMake(attributes.center.x, -attributes.center.y);
        else*/
            attributes.center = CGPointMake(attributes.center.x * 2, attributes.center.y);
        attributes.alpha = 0.0;
    }
    
    return attributes;
}

@end
