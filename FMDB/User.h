//
//  User.h
//  FMDB
//
//  Created by Xuezhipeng on 2017/4/18.
//  Copyright © 2017年 Xuezhipeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

/** 账号 */
@property (nonatomic, copy)     NSString                    *account;
/** 名字 */
@property (nonatomic, copy)     NSString                    *name;
/** 性别 */
@property (nonatomic, copy)     NSString                    *sex;
/** 头像地址 */
@property (nonatomic, copy)     NSString                    *portraitPath;
/** 图片 */
@property (strong, nonatomic)   NSData                      *imageData;
/** 手机号码 */
@property (nonatomic, assign)     float                    moblie;
/** 简介 */
@property (nonatomic, copy)    NSString                    *descn;
/** 年龄 */
@property (nonatomic, assign)  int                          age;

@property (nonatomic, assign)   long long                   createTime;

@property (nonatomic, assign)   int                        height;

@property (nonatomic, assign)   int                        field1;

@property (nonatomic, assign)   int                        field2;

@property (nonatomic, assign)     float                    xue;
@property (nonatomic, assign)     float                    xueTep;
@property (nonatomic, assign)     float                    xueTep2;


@end
