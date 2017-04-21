//
//  XDFMDB.m
//  FMDB
//
//  Created by Xuezhipeng on 2017/4/18.
//  Copyright © 2017年 Xuezhipeng. All rights reserved.
//

#import "XDFMDB.h"
#import "XDFMDBProperty.h"
@interface XDFMDB()
@property(nonatomic,copy)NSString *dbPath;//数据库地址
@property(nonatomic,strong)FMDatabase *db;//数据库对象
@property(nonatomic,strong)FMDatabaseQueue *dbQueue;//对象管理
@property(nonatomic,strong)XDFMDBVerson *sysObj;//对象管理
@property(nonatomic,strong)NSMutableArray *justIsAllSuccess;//判断是否全更新成功

@end
@implementation XDFMDB
//管理类对象单例
+ (instancetype)sharedInstance
{
    static XDFMDB * manager= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[XDFMDB alloc] init];
        NSString *doc =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)  lastObject];
        NSString *fileName = [doc stringByAppendingPathComponent:@"XD.sqlite"];
        manager.dbPath=fileName;
        NSLog(@"%@",fileName);
    });
    return manager;
}
-(void)initFMDBWith:(id<XDFMDBTableDelegate>)delegete{
    [XDFMDB sharedInstance].db=[[FMDatabase alloc]initWithPath:[XDFMDB sharedInstance].dbPath];
    [[XDFMDB sharedInstance].db open];
    [XDFMDB sharedInstance].db.logsErrors=YES;
    if([[XDFMDB sharedInstance].db goodConnection]){
        [XDFMDB sharedInstance].dbQueue=[FMDatabaseQueue databaseQueueWithPath:[XDFMDB sharedInstance].dbPath];
        if (![[XDFMDB sharedInstance] isTableExist:NSStringFromClass([XDFMDBVerson class])]) {
            //创建系统设置表 app版本更新逻辑预留
            [XDFMDB sharedInstance].sysObj=[[XDFMDBVerson alloc]init];
            //通过plist 文件获取应用当前本地版本
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            [XDFMDB sharedInstance].sysObj.verson=[infoDictionary objectForKey:@"CFBundleShortVersionString"];
            [XDFMDB creatTableWithClassName:[XDFMDBVerson class]];
            [XDFMDB insertDataFromObject:[XDFMDB sharedInstance].sysObj];
        }
    }
    [[XDFMDB sharedInstance].db close];
    self.delegate=delegete;
    [self.delegate creatNeedTable];
    //判断version看是否需要更新表
    NSArray *arr=[XDFMDB selecteDataWithClass:[XDFMDBVerson class]];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    XDFMDBVerson *verson=arr[0];
    if (![verson.verson isEqual:[infoDictionary objectForKey:@"CFBundleShortVersionString"]]) {
        self.justIsAllSuccess=[[NSMutableArray alloc]init];
        [self.delegate updateTable];
        //全部都成功才进行修改数据库表version
        if (![_justIsAllSuccess containsObject:@(NO)]) {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            if ([XDFMDB updateObject:[XDFMDBVerson class]
                          setValue:[NSString stringWithFormat:@"verson=%@", [infoDictionary objectForKey:@"CFBundleShortVersionString"]] where:@"XD_default_id=1"]) {
                
            }
        }
   }
}
/**
 创建表 默认有一个XD_default_id的主键
 
 @param className 类名
 @return 是否成功
 */
+(BOOL)creatTableWithClassName:(id)className{
    NSMutableString *sqlMuString;
    // 拼接sql语句
    sqlMuString = [NSMutableString stringWithFormat:@"create table if not exists %@ (XD_default_id integer primary key autoincrement,",NSStringFromClass(className)];
    NSDictionary *dic=[XDFMDBProperty getSQLDictionary:[className class]];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [sqlMuString appendFormat:@"%@ %@,",key,obj];
    }];
    // 去除最后的逗号
    NSRange rang = NSMakeRange(sqlMuString.length-1, 1);
    
    [sqlMuString deleteCharactersInRange:rang];
    
    [sqlMuString appendString:@")"];
    
    return  [[XDFMDB sharedInstance] executeSqlString:sqlMuString withCanRoll:YES];
}
#pragma mark ==========================插入===========================
+(BOOL)insertDataFromObject:(id)object{
    //确保有对象表
    [XDFMDB creatTableWithClassName:[object class]];
    // 创建可变字符串用于拼接sql语句
    NSMutableString * sqlString = [NSMutableString stringWithFormat:@"insert into %@ (",NSStringFromClass([object class])];
    NSDictionary *dic=[XDFMDBProperty getSQLDictionary:[object class]];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [sqlString appendFormat:@"%@,",key];
    }];
    // 去掉后面的逗号
    [sqlString deleteCharactersInRange:NSMakeRange(sqlString.length-1, 1)];
    // 拼接values
    [sqlString appendString:@") values ("];
    
    // 拼接字段值
    [[XDFMDBProperty getSQLDictionary:[object class]] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        // 拼接属性
        if ([object valueForKey:key]){
            if ([obj isEqualToString:@"text"]) {
                [sqlString appendFormat:@"'%@',",[object valueForKey:key]];
            } else if ([obj isEqualToString:@"customArr"] || [obj isEqualToString:@"customDict"]) { // 数组字典转处理
                NSData * data = [NSJSONSerialization dataWithJSONObject:[object valueForKey:key] options:0 error:nil];
                NSString * jsonString = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                [sqlString appendFormat:@"'%@',",jsonString];
            }else if ([obj isEqualToString:@"blob"]){ // NSData处理
                NSString * jsonString = [[NSString alloc] initWithData:[object valueForKey:key] encoding:(NSUTF8StringEncoding)];
                [sqlString appendFormat:@"'%@',",jsonString];
            }else {
                [sqlString appendFormat:@"%@,",[object valueForKey:key]];
            }
        }else {// 没有值就存NULL
            [sqlString appendFormat:@"'%@',",[object valueForKey:key]];
        }
    }];
    // 去掉后面的逗号
    [sqlString deleteCharactersInRange:NSMakeRange(sqlString.length-1, 1)];
    // 添加后面的括号
    [sqlString appendFormat:@");"];
    // 执行语句
    return  [[XDFMDB sharedInstance] executeSqlString:sqlString withCanRoll:YES];
}
//通过数组添加对象
+(BOOL)insertMutiDataFromObjectArr:(NSArray *)arr{
    for (id obj in arr) {
        if (![XDFMDB insertDataFromObject:obj]) {
            return NO;
        }
    }
    return YES;
}
//通过多参
+(BOOL)insertMutiDataFromObject:(id)object, ...{
    if (![XDFMDB insertDataFromObject:object]) {
        return NO;
    }
    va_list args;
    id obj;
    va_start(args, object);
    while ((obj = va_arg(args, id))) {
        if (![XDFMDB insertDataFromObject:obj]) {
            return NO;
        }
    }
    va_end(args);
    return YES;
}
#pragma mark =================查询=====================================
+(NSArray *)selecteDataWithClass:(id)className{
    NSString * sqlString = [NSMutableString stringWithFormat:@"select * from %@",NSStringFromClass([className class])];

    return [[XDFMDB sharedInstance] executeQueryWithSqlString:sqlString withObj:className] ;
}
//查询个数
+(NSInteger)getTotalRowsFormClass:(id)className{
    return [XDFMDB selecteDataWithClass:className].count;
}
//单条件查询
+(NSArray *)selectObject:(Class)className key:(id)key operate:(NSString *)operate value:(id)value{
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@ where %@ %@ '%@';",NSStringFromClass([className class]),key,operate,value];
    return [[XDFMDB sharedInstance] executeQueryWithSqlString:sqlString withObj:className] ;
}
//自定义
+(NSArray *)selecteDataWithSqlString:(NSString *)sqlString class:(id)className{
    
 return [[XDFMDB sharedInstance] executeQueryWithSqlString:sqlString withObj:className] ;
}
#pragma mark =================更新=====================================
+(BOOL)updateObject:(Class)className setValue:(NSString *)setValue where:(NSString *)judge{
    //拼接sql语句
    NSMutableString *sqlString = [[NSMutableString alloc] initWithFormat:@"update %@ set ",NSStringFromClass([className class])];
    
    [sqlString appendFormat:@"%@",setValue];
    
    [sqlString appendString:@" where "];
    
    [sqlString appendFormat:@"%@",judge];
    return [[XDFMDB sharedInstance] executeSqlString:sqlString withCanRoll:YES];

}
#pragma mark ===================删除========================================
//删除表
+(BOOL)deleteTableWithTableName:(id)className{
    NSString *sqlString = [NSString stringWithFormat:@"drop table %@",NSStringFromClass([className class])];
    return  [[XDFMDB sharedInstance] executeSqlString:sqlString withCanRoll:NO];
}
//清表内容
+(BOOL)clearTableWithName:(id)className{
    NSString *sqlString = [NSString stringWithFormat:@"delete from %@",[className class]];
    return [[XDFMDB sharedInstance] executeSqlString:sqlString withCanRoll:NO];
}
//写删除的条件删除
+(BOOL)deleteObject:(Class)className withString:(NSString *)string{
    NSString * sqlString = [NSString stringWithFormat:@"delete from %@ where %@;",[className class],string];
     return [[XDFMDB sharedInstance] executeSqlString:sqlString withCanRoll:YES];
}
#pragma mark ==========执行sql语句 除了查询==============================
+(BOOL)executeSqlString:(NSString *)sqlString{
    return  [[XDFMDB sharedInstance] executeSqlString:sqlString withCanRoll:YES];
}
//带回滚的操作
-(BOOL)executeSqlString:(NSString *)sqlString withCanRoll:(BOOL)roll{
    
    __block BOOL isSuccess=NO;
    if (roll) {
        [[XDFMDB sharedInstance].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            if ([db executeUpdate:sqlString]) {
                isSuccess=YES;
            }
            else{
                //失败回滚
                *rollback=YES;
                isSuccess=NO;
            }
        }];
    }
    else{
        [[XDFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
            if ([db executeUpdate:sqlString]) {
                isSuccess=YES;
            }
            else{isSuccess=NO;}
        }];
    }
    return isSuccess;
}
-(NSArray *)executeQueryWithSqlString:(NSString *)sqlString withObj:(id)object{
    __block NSMutableArray *models = [NSMutableArray array];
    [[XDFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
        if ([db goodConnection]) {
            FMResultSet *resultSet = [db executeQuery:sqlString];
            NSArray * arr = [XDFMDBProperty getUserNeedAttributeListWithClass:[object class]];
            // 获取属性列表名和sql数据类型 比如  name : text
            NSDictionary * dict = [XDFMDBProperty getSQLDictionary:[object class]];
            while ([resultSet next]) {
               id objc = [[[object class] alloc]init];
                // 默认第0个元素为表格主键 所以元素从第一个开始
                // 使用KVC完成赋值
                for ( int i = 0; i < arr.count; i++) {
                    
                    if ([dict[arr[i]] isEqualToString:@"text"]) {
                        [objc setValue:[resultSet stringForColumn:arr[i]] forKey:arr[i]];
                    } else if ([dict[arr[i]] isEqualToString:@"real"]) {
                        [objc setValue:@([resultSet doubleForColumn:arr[i]]) forKey:arr[i]];
                        NSLog(@"%@",@([resultSet doubleForColumn:arr[i]]));
                        
                    } else if ([dict[arr[i]] isEqualToString:@"integer"]) {
                        [objc setValue:@([resultSet intForColumn:arr[i]]) forKey:arr[i]];
                        
                    } else if ([dict[arr[i]] isEqualToString:@"customArr"]){ // 数组处理
                        NSData * data = [[resultSet stringForColumn:arr[i]] dataUsingEncoding:NSUTF8StringEncoding];
                        NSArray * resultArray  = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        [objc setValue:resultArray forKey:arr[i]];
                    }  else if ([dict[arr[i]] isEqualToString:@"customDict"]) { // 字典处理
                        NSData * data = [[resultSet stringForColumn:arr[i]] dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary * resultDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        [objc setValue:resultDict forKey:arr[i]];
                        
                    } else if ([dict[arr[i]] isEqualToString:@"blob"]) { // 二进制处理
                        NSData * data = [[resultSet stringForColumn:arr[i]] dataUsingEncoding:NSUTF8StringEncoding];
                        [objc setValue:data forKey:arr[i]];
                    }
                }
                [models addObject:objc];
            }
            
        }
    }];
    return models;
}

#pragma mark - ===============更新数据库表文件 app版本更新===================

/**
 数据库更新 并迁移表的数据

 @param className 表类名
 */
+(void)appUpdateTable:(id)className{
    //判断是否有此表
    if ([[XDFMDB sharedInstance] isTableExist:NSStringFromClass([className class])]) {
     
        //获取到未拥有的键 准备迁移表 创建临时表 迁移数据 删除原表 修改表名
        if ([self creatTempTableWithClassName:[className class]]) {
            NSArray *oldArr=[self getPropertyArrWithTable:[className class]];
            if (oldArr.count>0) {
                NSArray *newArr=[XDFMDBProperty getUserNeedAttributeListWithClass:[className class]];
                NSMutableArray *needChangeArr=[[NSMutableArray alloc]init];
                for (NSString *property in oldArr) {
                    if ([newArr containsObject:property]) {
                        [needChangeArr addObject:property];
                    }
                }
                //获得需要迁移的数据库字段
                NSMutableString *sqlMuString;
                sqlMuString = [NSMutableString stringWithFormat:@"Insert into %@ (",[NSString stringWithFormat:@"%@%@",NSStringFromClass(className),@"temp"]];
                [needChangeArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [sqlMuString appendFormat:@"%@,",obj];
                }];
                // 去掉后面的逗号
                [sqlMuString deleteCharactersInRange:NSMakeRange(sqlMuString.length-1, 1)];
                [sqlMuString appendString:@") select "];
                [needChangeArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [sqlMuString appendFormat:@"%@,",obj];
                }];
                // 去掉后面的逗号
                [sqlMuString deleteCharactersInRange:NSMakeRange(sqlMuString.length-1, 1)];
                 [sqlMuString appendFormat:@" from %@",NSStringFromClass([className class])];
                if ( [self executeSqlString:sqlMuString]) {
                    //迁移数据成功 删除原表
                    if ([self deleteTableWithTableName:[className class]]) {
                        //修改临时表 删除临时表
                        if([self executeSqlString:[NSString stringWithFormat: @"ALTER TABLE %@ RENAME TO %@",[NSString stringWithFormat:@"%@%@",NSStringFromClass(className),@"temp"],NSStringFromClass(className)]]){
                            NSLog(@"迁移成功");
                        }else{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
                    }else{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
                }else{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
            }else{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
        }else{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
        }else{
        [self creatTableWithClassName:className];
    }
}

/**
 是否存在表

 @param tableName 表明
 @return 是否
 */
- (BOOL) isTableExist:(NSString *)tableName
{
    __block BOOL isExsit=NO;
    [[XDFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *XD = [db executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
        while ([XD next])
        {
            // just print out what we've got in a number of formats.
            NSInteger count = [XD intForColumn:@"count"];
            if (0 == count)
            {
                isExsit=NO;
            }
            else
            {
                isExsit=YES;
            }
        }
    }];
    return isExsit;
/**
 创建临时表表明为name加temp

 @param className 表名
 @return 是否成功

 */
}
+(BOOL)creatTempTableWithClassName:(Class)className{
    NSMutableString *sqlMuString;
    // 拼接sql语句
    sqlMuString = [NSMutableString stringWithFormat:@"create table if not exists %@ (XD_default_id integer primary key autoincrement,",[NSString stringWithFormat:@"%@%@",NSStringFromClass(className),@"temp"]];
    NSDictionary *dic=[XDFMDBProperty getSQLDictionary:[className class]];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
        [sqlMuString appendFormat:@"%@ %@,",key,obj];
    }];
    // 去除最后的逗号
    NSRange rang = NSMakeRange(sqlMuString.length-1, 1);
    
    [sqlMuString deleteCharactersInRange:rang];
    
    [sqlMuString appendString:@")"];
    
    return  [[XDFMDB sharedInstance] executeSqlString:sqlMuString withCanRoll:YES];
}

/**
 获取这个表的字段数组

 @param className 表明
 @return 字段数组
 */
+(NSArray *)getPropertyArrWithTable:(id)className{
    __block NSMutableArray *propertyArr=[[NSMutableArray alloc]init];
    [[XDFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
        if ([db goodConnection]) {
             NSString * sqlString = [NSMutableString stringWithFormat:@"select * from %@",NSStringFromClass([className class])];
            FMResultSet *resultSet = [db executeQuery:sqlString];
            NSDictionary *dic=[resultSet columnNameToIndexMap];
            [propertyArr addObjectsFromArray:[dic allKeys]];
            while ([resultSet next]) {
                
            }
        }
    }];
    return propertyArr;
}
+(void)reCreatTable:(id)className{
    //判断是否有此表
    if ([[XDFMDB sharedInstance] isTableExist:NSStringFromClass([className class])]) {
        //获取到未拥有的键 准备迁移表 创建临时表 迁移数据 删除原表 修改表名
        if ([self creatTempTableWithClassName:[className class]]) {
            NSArray *oldArr=[self getPropertyArrWithTable:[className class]];
            if (oldArr.count>0) {
                NSArray *newArr=[XDFMDBProperty getUserNeedAttributeListWithClass:[className class]];
                NSMutableArray *needChangeArr=[[NSMutableArray alloc]init];
                for (NSString *property in oldArr) {
                    if ([newArr containsObject:property]) {
                        [needChangeArr addObject:property];
                    }
                }
            if ([self deleteTableWithTableName:[className class]]) {
                        //修改临时表表名
                        if([self executeSqlString:[NSString stringWithFormat: @"ALTER TABLE %@ RENAME TO %@",[NSString stringWithFormat:@"%@%@",NSStringFromClass(className),@"temp"],NSStringFromClass(className)]]){
                                NSLog(@"重建成功");
                        }{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
                    }{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
            }{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
        }{ [[XDFMDB sharedInstance].justIsAllSuccess addObject:@(NO)];}
    }else{
        [self creatTableWithClassName:className];
    }
}
@end
//系统设置对象 默认创建verson表
@implementation XDFMDBVerson

@end
