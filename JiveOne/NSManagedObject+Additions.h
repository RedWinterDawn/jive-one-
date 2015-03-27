//
//  NSManagedObject+JCCoreDataAdditions.h
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Primitives)

-(void)setPrimitiveValueFromStringValue:(NSString *)string forKey:(NSString *)key;
-(NSString *)stringValueFromPrimitiveValueForKey:(NSString *)key;

// Booleans
-(void)setPrimitiveValueFromBoolValue:(BOOL)boolean forKey:(NSString *)key;
-(BOOL)boolValueFromPrimitiveValueForKey:(NSString *)key;

// Integers
-(void)setPrimitiveValueFromIntegerValue:(NSInteger)integer forKey:(NSString *)key;
-(NSInteger)integerValueFromPrimitiveValueForKey:(NSString *)key;

// Double
-(void)setPrimitiveValueFromDoubleValue:(double)doubleValue forKey:(NSString *)key;
-(double)doubleValueFromPrimativeValueForKey:(NSString *)key;

// Floats
-(void)setPrimitiveValueFromFloatValue:(float)value forKey:(NSString *)key;
-(float)floatValueFromPrimitiveValueForKey:(NSString *)key;

// Images
-(void)setPrimitiveValueFromImage:(UIImage *)image forKey:(NSString *)key;
-(UIImage *)imageFromPrimitiveValueForKey:(NSString *)key;

// Objects
-(void)setPrimitiveValueFromObject:(id)object forKey:(NSString *)key;
-(id)objectFromPrimitiveValueForKey:(NSString *)key;

-(void)setPrimitiveValueFromURL:(NSURL *)url forKey:(NSString *)key;
-(NSURL *)urlFromPrimitiveValueForKey:(NSString *)key;

@end

@interface NSManagedObject (JRNIdentifiers)

+(NSString *)identifierFromJrn:(NSString *)jrn index:(NSUInteger)index;

@end