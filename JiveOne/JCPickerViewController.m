//
//  JCPickerViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPickerViewController.h"

#import <QuartzCore/QuartzCore.h>

#define PICKER_SELECT_BUTTON_BORDER_WIDTH 1.0f
#define PICKER_SELECT_BUTTON_BORDER_COLOR [UIColor lightGrayColor]
#define PICKER_SELECT_BUTTON_CORNER_RADIUS 2.0f

@interface JCPickerViewController ()
{
    BOOL _pickerVisible;
    NSInteger _verticalSpacing;
}

@end

@implementation JCPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectBtn.layer.borderWidth = PICKER_SELECT_BUTTON_BORDER_WIDTH;
    _selectBtn.layer.borderColor = PICKER_SELECT_BUTTON_BORDER_COLOR.CGColor;
    _selectBtn.layer.cornerRadius = PICKER_SELECT_BUTTON_CORNER_RADIUS;
    _selectBtn.layer.masksToBounds = true;
    
    
    _pickerVisible = TRUE;
    [self hidePicker:false];
    // Do any additional setup after loading the view.
}

-(void)awakeFromNib{
    _verticalSpacing = self.pickerContainerBottomConstraint.constant;
}

-(NSString *)titleForRow:(NSInteger)row
{
    return [NSString stringWithFormat:@"Row %i", row];
}

-(NSInteger)numberOfRows
{
    return 0;
}

#pragma mark - IBActions -

- (IBAction)select:(id)sender {
    if(_pickerVisible) {
        [self hidePicker:true];
    } else {
        [self showPicker:true];
    }
}

- (IBAction)done:(id)sender {
    [self hidePicker:TRUE];
}

-(IBAction)close:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(pickerViewControllerShouldDismiss:)]) {
        [_delegate pickerViewControllerShouldDismiss:self];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - Private -

-(void)showPicker:(BOOL)animated{
    if (_pickerVisible) {
        return;
    }
    __unsafe_unretained JCPickerViewController *weakSelf = self;
    _pickerContainerBottomConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:(animated ? 0.6 : 0.0)
                     animations:^{
                         
                         [weakSelf.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _pickerVisible = true;
                     }];
}

-(void)hidePicker:(BOOL)animated{
    if(!_pickerVisible) {
        return;
    }
    __unsafe_unretained JCPickerViewController *weakSelf = self;
    _pickerContainerBottomConstraint.constant = -_pickerContainerHeightConstraint.constant;
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:(animated ? 0.6 : 0.0)
                     animations:^{
                         [weakSelf.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _pickerVisible = false;
                     }];
}



#pragma mark - Delegate Handlers -

#pragma mark UIPickerDataSource Methods

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.numberOfRows;
}

#pragma mark UIPickerDelegate Methods

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self titleForRow:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    [self hidePicker:YES];
}

@end
