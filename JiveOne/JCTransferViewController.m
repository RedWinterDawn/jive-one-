//
//  JCTransferViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTransferViewController.h"

@implementation JCTransferViewController

#pragma mark - IBActions -

-(IBAction)cancel:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(shouldCancelTransferViewController:)])
        [_delegate shouldCancelTransferViewController:self];
}

-(IBAction)initiateCall:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(transferViewController:shouldDialNumber:)]){
        NSString *dialString = self.formattedPhoneNumberLabel.dialString;
        id <JCPhoneNumberDataSource> phoneNumber = [self phoneNumberForNumber:dialString];
        [_delegate transferViewController:self shouldDialNumber:phoneNumber];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JCPhoneNumberDataSource> phoneNumber = [self objectAtIndexPath:indexPath];
    self.formattedPhoneNumberLabel.dialString = phoneNumber.dialableNumber;
    if (_delegate && [_delegate respondsToSelector:@selector(transferViewController:shouldDialNumber:)])
        [_delegate transferViewController:self shouldDialNumber:phoneNumber];
}

@end
