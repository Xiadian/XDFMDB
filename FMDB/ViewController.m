//
//  ViewController.m
//  FMDB
//
//  Created by Xuezhipeng on 2017/4/10.
//  Copyright © 2017年 Xuezhipeng. All rights reserved.
//

#import "ViewController.h"
#import "XDFMDB.h"
#import "User.h"
#import "XDFMDBProperty.h"
@interface ViewController ()<XDFMDBTableDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化fmdb 并创建version表 写这个方法实现俩个代理就可以创建所需的数据库及以后的更新
    [[XDFMDB sharedInstance]initFMDBWith:self];
    User *u1=[[User alloc]init];
    u1.name=@"s";
    u1.moblie=124.1241;
    User *u2=[[User alloc]init];
    u2.name=@"d";
    u2.moblie=124.1;
    
    User *u3=[[User alloc]init];
    u3.name=@"f";
    u3.moblie=1.1241;

    //增
    [XDFMDB insertMutiDataFromObject:u1,u2,u3,nil];
    //改
    [XDFMDB updateObject:[User class] setValue:@"name='lisi'" where:@"name='s'"];
    //查 数组里都是相应的对象
    NSArray *arr=[XDFMDB selecteDataWithClass:[User class]];
    //删除表
    [XDFMDB deleteTableWithTableName:[User class]];
    //清空表的内容
    [XDFMDB clearTableWithName:[User class]];
    
    
    
   
}
//需要创建的表
-(void)creatNeedTable{
    //创建表
    [XDFMDB creatTableWithClassName:[User class]];
}
//本次项目要有更新的表 其实全写上就不会落下了
-(void)updateTable{
    //重新建立新表
    [XDFMDB reCreatTable:[User class]];
    //检查表并有数据迁移
    [XDFMDB appUpdateTable:[User class]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
