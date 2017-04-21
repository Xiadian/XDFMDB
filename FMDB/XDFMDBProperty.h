//
//  XDFMDBProperty.h
//  FMDB
//
//  Created by Xuezhipeng on 2017/4/18.
//  Copyright © 2017年 Xuezhipeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XDFMDBProperty : NSObject 
/**
 *  获取类中的属性和类型为数据库类型 例{@"name":@"text"}
 *
 *  @param className 类名
 *
 *  @return 类中的属性和类型, 属性名为key，属性数据库类型为value
 */
+ (NSDictionary *)getSQLDictionary:(id)className;
/**
 *  获取属性名列表 例 name
 *
 *  @param className 类名
 *
 *  @return 属性名列表
 */
+ (NSArray *)getUserNeedAttributeListWithClass:(id)className;


@end
