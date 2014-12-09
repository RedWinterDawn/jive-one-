//
//  JCPbxConfigurationViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPbxConfigurationViewController.h"
#import "JCAuthenticationManager.h"
#import "PBX.h"

@interface JCPbxConfigurationViewController ()
{
    JCAuthenticationManager *_authenticationManger;
}

@property (strong, nonatomic) NSArray *pbxs;

@end

@implementation JCPbxConfigurationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pbxs = [PBX MR_findAllSortedBy:@"name" ascending:YES];
    
    _authenticationManger = [JCAuthenticationManager sharedInstance];
    [_authenticationManger addObserver:self forKeyPath:NSStringFromSelector(@selector(pbx)) options:0 context:NULL];
    
    PBX *pbx = _authenticationManger.pbx;
    
    NSInteger index = [self.pbxs indexOfObject:pbx];
    [self.pickerView selectRow:index inComponent:0 animated:NO];
    
    NSString *pbxName = pbx.name;
    [self.selectBtn setTitle:pbxName forState:UIControlStateNormal];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(pbx))]) {
        JCAuthenticationManager *manager =  (JCAuthenticationManager *)object;
        [self.selectBtn setTitle:manager.pbx.name forState:UIControlStateNormal];
        
    }
}

-(void)dealloc{
    [_authenticationManger removeObserver:self forKeyPath:NSStringFromSelector(@selector(pbx))];
}

-(NSString *)titleForRow:(NSInteger)row
{
    PBX *pbx = [_pbxs objectAtIndex:row];
    return pbx.name;
}

-(NSInteger)numberOfRows
{
    return [_pbxs count];
}

#pragma mark - IBActions -

-(IBAction)close:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(pbxConfigurationViewControllerShouldDismiss:)]) {
        [_delegate pbxConfigurationViewControllerShouldDismiss:self];
    }
    else
    {
        [super close:sender];
    }
}

#pragma mark - Delegate Handlers -

#pragma mark UIPickerDelegate Methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    PBX *pbx  = [_pbxs objectAtIndex:row];
    
    NSArray *pbxs = _pbxs;
    for (PBX *item in pbxs) {
        if (pbx == item){
            item.active = TRUE;
        }
        else{
            item.active = FALSE;
        }
    }
    
    // If we have changes, save them.
    if (pbx.managedObjectContext.hasChanges) {
        __autoreleasing NSError *error;
        if(![pbx.managedObjectContext save:&error])
            NSLog(@"%@", [error description]);
    }
    
    _authenticationManger.pbx = pbx;
    
    [super pickerView:pickerView didSelectRow:row inComponent:component];
}

@end
