//
//  JCSettings.h
//  JCAuthentication
//
//  Created by Robert Barclay on 8/6/15.
//
//

@import Foundation;

@interface JCSettings : NSObject

-(instancetype)initWithDefaults:(NSUserDefaults *)defaults;

@property (nonatomic, readonly) NSUserDefaults *userDefaults;

-(void)setBoolValue:(BOOL)value forKey:(NSString *)key;
-(void)setValue:(NSString *)value forKey:(NSString *)key;
-(void)setFloatValue:(float)value forKey:(NSString *)key;

// Defaults loading
-(void)loadDefaultsFromFile:(NSString *)file;
-(void)loadDefaultsFromFile:(NSString *)file bundle:(NSBundle *)bundle;
-(void)loadDefaults:(NSDictionary *)defaults;

@end