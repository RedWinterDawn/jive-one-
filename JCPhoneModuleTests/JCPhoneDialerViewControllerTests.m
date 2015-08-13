//
//  JCPhoneDialerViewControllerSpecs.m
//  JiveOne
//
//  Created by Robert Barclay on 8/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"

#import "JCPhoneDialerViewController.h"

SpecBegin(PhoneDialerViewController)

describe(@"PhoneDialerViewController load from nib", ^{
    
    __block JCPhoneDialerViewController *_vc;
    
    beforeEach(^{
        _vc = [[JCPhoneDialerViewController alloc] initWithNibName:nil bundle:nil];
        UIView *view = _vc.view;
        expect(view).toNot.beNil();
    });
    
    context(@"Initialization", ^{
        
        it(@"should be instanciated", ^{
            expect(_vc).toNot.beNil();
            expect(_vc).to.beInstanceOf([JCPhoneDialerViewController class]);
        });
        
        it(@"should have an collection view", ^{
            expect(_vc.collectionView).toNot.beNil();
        });
    });
    
});

SpecEnd