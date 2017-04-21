//
//  XDFMDB.h
//  FMDB
//
//  Created by Xuezhipeng on 2017/4/18.
//  Copyright © 2017年 Xuezhipeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>
@protocol XDFMDBTableDelegate <NSObject>

/**
 代理方法必须实现 创建需要的表
 +(BOOL)creatTableWithClassName:(id)className;
 */
-(void)creatNeedTable;

/**
 app版本将需要更新的表写在这个方法里需要实现的
 调用+(void)appUpdateTable:(id)className;
 调用+(void)reCreatTable:(id)className;

 */
-(void)updateTable;
@end

@interface XDFMDBVerson : NSObject
/**
 版本号
 */
@property(nonatomic,strong)NSString *verson;
@end
@interface XDFMDB : NSObject

/**
 FMDB代理用来创建所需表更新表
 */
@property(nonatomic,strong)id<XDFMDBTableDelegate>delegate;
/**
 FMDB管理类对象

 @return FMDB管理对象
 */
+ (instancetype)sharedInstance;

/**
 初始化配置
 */
-(void)initFMDBWith:(id<XDFMDBTableDelegate>)delegete;
/**
 *  根据类名创建表格,默认主键为XD_default_id
 *
 *  @param className  类名
 */
+(BOOL)creatTableWithClassName:(id)className;
#pragma mark - =============== 插入数据 ========================
/**
 *  插入数据
 *  该方法会将模型对象插入到对象类型所对应的表格中
 *  @param object 模型对象
 */
+(BOOL)insertDataFromObject:(id)object;

/**
 多参插入

 @param object 插入对象 最后别忘了nil
 @return 插入是否成功
 */
+(BOOL)insertMutiDataFromObject:(id)object, ...;

/**
 插入通过数组

 @param arr 对象数组
 @return 是否成功
 */
+(BOOL)insertMutiDataFromObjectArr:(NSArray *)arr;

#pragma mark -
#pragma mark - =============== 查询数据 ===============
/**
 *  获取表格中所有数据,
 */
+ (NSArray *)selecteDataWithClass:(id)className;
/**
 *  获取表格中数据行数
 */
+ (NSInteger)getTotalRowsFormClass:(id)className;

/**
 *  单条件查询
 *
 *  @param className   类名
 *  @param key   属性名 例 @"name"
 *  @param operate   符号 例 @"=" > <
 *  @param value 值 例 @"zhangsan"
 *
 *  @return 查询结果
 */
+ (NSArray *)selectObject:(Class)className key:(id)key operate:(NSString *)operate value:(id)value;

/**
 *  自定义语句查询
 *
 *  @param sqlString 自定义的sql语句
 *  @param className 类名
 *
 *  @return 查询结果
 */
+(NSArray *)selecteDataWithSqlString:(NSString *)sqlString class:(id)className;
#pragma mark -
#pragma mark - =============== 更新数据 ===============
/**
 *  数据更新
 *
 *  @param className             类名
 *  @param setValue   要更新的内容 例 @"name=lisi"
 *  @param judge 更新条件 例 @"id=5 and name='zhangsan'"
 */
+(BOOL)updateObject:(Class)className setValue:(NSString *)setValue where:(NSString *)judge;

#pragma mark -
#pragma mark - =============== 删除数据 ======================
/**
 *  删除数据
 *
 *  @param className 类名
 *  @param string    删除语句,字符串需要加上单引号 例@"name = 'Chris'" / @"id = 1234" / @"integer > 1234";
 *
 *  @return 删除结果
 */
+ (BOOL)deleteObject:(Class)className withString:(NSString *)string;

/**
 *  清空数据库某表格的内容
 *
 *  @param className 类名
 *
 *  @return 清空结果
 */
+ (BOOL)clearTableWithName:(id)className;

/**
 *  删除数据库表格
 *
 *  @param className 类名
 *
 *  @return 删除结果
 */
+(BOOL)deleteTableWithTableName:(id)className;
/**
 *  执行自定义的sql语句
 *
 *  @param sqlString 自定义的sql语句
 *
 *  @return 执行结果
 */
+(BOOL)executeSqlString:(NSString *)sqlString;
#pragma mark - =================更新数据库表文件==============================

/**
 app更新表迁移数据

 @param className 类名
 */
+(void)appUpdateTable:(id)className;

/**
 app更新重新生成表不要数据
 
 @param className 类名
 */
+(void)reCreatTable:(id)className;

@end
