//
//  JCMessageViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"
#import <MBContactPicker/MBContactPicker.h>
#import "ContactGroup.h"

@interface JCMessageViewController : UIViewController <MBContactPickerDelegate, MBContactPickerDataSource,
HPGrowingTextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) ClientEntities *person;
@property (nonatomic) NSString *conversationId;
@property (nonatomic) ContactGroup *contactGroup;
@property (nonatomic) JCMessageType messageType;

@end
