//
//  NSManagedObject+JCCoreDataAdditions.m
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "NSManagedObject+JCCoreDataAdditions.h"

@implementation NSManagedObject (JCCoreDataAdditions)

#pragma mark - Setters -

-(void)setPrimitiveValueFromBoolValue:(BOOL)boolean forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:[NSNumber numberWithBool:boolean] forKey:key];
    [self didChangeValueForKey:key];
}

-(void)setPrimitiveValueFromIntegerValue:(NSInteger)integer forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:[NSNumber numberWithInteger:integer] forKey:key];
    [self didChangeValueForKey:key];
}

-(void)setPrimitiveValueFromDoubleValue:(double)doubleValue forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:[NSNumber numberWithDouble:doubleValue] forKey:key];
    [self didChangeValueForKey:key];
}

-(void)setPrimitiveValueFromFloatValue:(float)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:[NSNumber numberWithFloat:value] forKey:key];
    [self didChangeValueForKey:key];
}

-(void)setPrimitiveValueFromImage:(UIImage *)image forKey:(NSString *)key
{
    NSData *imageData = UIImagePNGRepresentation(image);
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:imageData forKey:key];
    [self didChangeValueForKey:key];
}

-(void)setPrimitiveValueFromObject:(id)object forKey:(NSString *)key
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:objectData forKey:key];
    [self didChangeValueForKey:key];
}

-(void)setPrimitiveValueFromURL:(NSURL *)url forKey:(NSString *)key
{
    NSString *string = url.absoluteString;
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:string forKey:key];
    [self didChangeValueForKey:key];
}

#pragma mark - Getters -

-(BOOL)boolValueFromPrimitiveValueForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    return value.boolValue;
}

-(NSInteger)integerValueFromPrimitiveValueForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    return value.integerValue;
}

-(double)doubleValueFromPrimativeValueForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    return value.doubleValue;
}

-(float)floatValueFromPrimitiveValueForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    return value.floatValue;
}

-(UIImage *)imageFromPrimitiveValueForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSData *imageData = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    if (imageData)
        return [UIImage imageWithData:imageData];
    return nil;
}

-(id)objectFromPrimitiveValueForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSData *objectData = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    if (objectData)
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    return nil;
}

-(NSURL *)urlFromPrimitiveValueForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSString *string = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    if (string)
        return [NSURL URLWithString:string];
    return nil;
}

@end
