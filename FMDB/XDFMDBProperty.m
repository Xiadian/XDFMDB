//
//  RSFMDBProperty.m
//  FMDB
//
//  Created by Xuezhipeng on 2017/4/18.
//  Copyright © 2017年 Xuezhipeng. All rights reserved.
//

#import "XDFMDBProperty.h"
#import <objc/runtime.h>
@implementation XDFMDBProperty

/**
 获取SQL的属性和类型列表

 @param NSDictionary 属性字典 例子：name : text oc的为 name :NSString
 @return 属性字典
 */
#pragma mark =============== 获取SQL的属性和类型列表 ===============
+ (NSDictionary *)getSQLDictionary:(id)className {
    return [NSDictionary dictionaryWithObjects:[self getUserNeedSQLPropertyTypeListWithClass:className] forKeys:[self getUserNeedAttributeListWithClass:className]];
}
#pragma mark =============== 获取属性SQL类型列表 ===============
/// 获取属性SQL类型列表
+ (NSArray *)getUserNeedSQLPropertyTypeListWithClass:(id)className {
    return [self getSQLPropertyTypeListWithClass:className];
}

+ (NSArray *)getSQLPropertyTypeListWithClass:(id)className {
    NSMutableArray *tempArrayM = [NSMutableArray array];
    
    [[self getUserNeedOCPropertyTypeListWithClass:className] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
     [tempArrayM addObject:[self OCConversionTyleToSQLWithString:obj]];
    }];
    return  tempArrayM;
}
#pragma mark =============== 获取OC类型列表 例：NSString ===============
/**
 *  获取属性OC类型列表
 *
 *  @param className 类名
 *
 *  @return 类型列表
 */
+ (NSArray *)getUserNeedOCPropertyTypeListWithClass:(id)className {
    
    // 获取当前类的所有属性
    unsigned int count;// 记录属性个数
    objc_property_t *properties = class_copyPropertyList([className class], &count);
    
    NSMutableArray *tempArrayM = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        // 转换为Objective C 字符串
        NSString *type = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
         [tempArrayM addObject:[self getAttributesWith:type]];
    }
    return tempArrayM;
}
//============== 获取属性对应的OC类型 ===============
+ (NSString *)getAttributesWith:(NSString *)type {
    
    NSString *firstType = [[[type componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
    
    NSDictionary *dict = @{@"f":@"float",
                           @"i":@"int",
                           @"d":@"double",
                           @"l":@"long",
                           @"q":@"long",
                           @"c":@"BOOL",
                           @"B":@"BOOL",
                           @"s":@"short",
                           @"I":@"NSInteger",
                           @"Q":@"NSUInteger",
                           @"#":@"Class"};
    
    for (NSString *key in dict.allKeys) {
        if ([key isEqualToString:firstType]) {
            return  [dict valueForKey:firstType];
        }
    }
    return [firstType componentsSeparatedByString:@"\""][1];
}
/// OC类型转SQL类型
+ (NSString *)OCConversionTyleToSQLWithString:(NSString *)String {
    if ([String isEqualToString:@"long"] || [String isEqualToString:@"int"] || [String isEqualToString:@"BOOL"]) {
        return @"integer";
    }
    if ([String isEqualToString:@"NSData"]) {
        return @"blob";
    }
    if ([String isEqualToString:@"double"] || [String isEqualToString:@"float"]) {
        return @"real";
    }
    // 自定义数组标记
    if ([String isEqualToString:@"NSArray"] || [String isEqualToString:@"NSMutableArray"]) {
        return @"customArr";
    }
    // 自定义字典标记
    if ([String isEqualToString:@"NSDictionary"] || [String isEqualToString:@"NSMutableDictionary"]) {
        return @"customDict";
    }
    return @"text";
}


#pragma mark =============== 获取属性名列表 例：name===============
/// 获取属性名列表
+ (NSArray *)getUserNeedAttributeListWithClass:(id)className {
    NSMutableArray *tempArrayM = [NSMutableArray arrayWithArray:[self getAttributeListWithClass:className]];
    return tempArrayM;
}
/// 获取当前类的所有属性
+ (NSArray *)getAttributeListWithClass:(id)className {
    // 记录属性个数
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([className class], &count);
    
    NSMutableArray *tempArrayM = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        
        // 转换为Objective C 字符串
        NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        
        NSAssert(![name isEqualToString:@"index"], @"在model中使用index作为属性,否则会引起语法错误");
        
        if ([name isEqualToString:@"hash"]) {
            break;
        }
        
        [tempArrayM addObject:name];
    }
    free(properties);
    return tempArrayM;
}

@end
