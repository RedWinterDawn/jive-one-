//
//  JCPickerViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCPickerViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *pickerContainer;
@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerContainerBottomConstraint;

-(NSString *)titleForRow:(NSInteger)row;

@property (nonatomic, readonly) NSInteger numberOfRows;

-(IBAction)select:(id)sender;
-(IBAction)done:(id)sender;
-(IBAction)close:(id)sender;

@end
