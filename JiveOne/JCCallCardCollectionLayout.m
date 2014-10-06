//
//  JCCallCardCollectionLayout.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionLayout.h"
#import "JCCallCardManager.h"
#import "JCCallCardCollectionViewCell.h"

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
    CGFloat height = 180.0f;
    NSUInteger calls = [JCCallCardManager sharedManager].totalCalls;
    if (calls == 1)
        return self.collectionView.bounds.size.height;
    
    if(calls == 2)
        return ((self.collectionView.bounds.size.height - 10) / 2 );
    
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
    CGFloat height = self.itemInsets.top + (rowCount * self.cellHeight) + (rowCount - 1) * self.interItemSpacingY + self.itemInsets.bottom;
    
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
    
    self.deleteIndexPaths = [NSMutableArray array];
    self.insertIndexPaths = [NSMutableArray array];
    
    for (UICollectionViewUpdateItem *update in updateItems)
    {
        if (update.updateAction == UICollectionUpdateActionDelete)
            [self.deleteIndexPaths addObject:update.indexPathBeforeUpdate];
        else if (update.updateAction == UICollectionUpdateActionInsert)
            [self.insertIndexPaths addObject:update.indexPathAfterUpdate];
    }
}

-(void)finalizeCollectionViewUpdates
{
    [super finalizeCollectionViewUpdates];
    
    // release the insert and delete index paths
    self.deleteIndexPaths = nil;
    self.insertIndexPaths = nil;
}


-(UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // Must call super
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    if ([self.insertIndexPaths containsObject:itemIndexPath])
    {
        // only change attributes on inserted cells
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        // Configure attributes ...
        JCCallCard *callCard = [[JCCallCardManager sharedManager].currentCalls objectAtIndex:itemIndexPath.row];
        if (callCard.isIncoming)
            attributes.center = CGPointMake(attributes.center.x, -attributes.center.y);
        else
            attributes.center = CGPointMake(attributes.center.x * 2, attributes.center.y);
        attributes.alpha = 0.0;

    }
    
    return attributes;
}

-(UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // So far, calling super hasn't been strictly necessary here, but leaving it in
    // for good measure
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    if ([self.deleteIndexPaths containsObject:itemIndexPath])
    {
        // only change attributes on deleted cells
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        
        [self.collectionView.viewForBaselineLayout.layer setSpeed:1.5f];
        
        JCCallCardCollectionViewCell *cell = (JCCallCardCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:itemIndexPath];
        JCCallCard *callCard = cell.callCard;
        
        // Configure attributes ...
        if (callCard.isIncoming)
            attributes.center = CGPointMake(attributes.center.x, -attributes.center.y);
        else
            attributes.center = CGPointMake(attributes.center.x * 10, attributes.center.y);
        attributes.alpha = 0.0;
    }
    
    return attributes;
}



@end
