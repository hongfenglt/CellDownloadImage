/**
 *                 Created by 洪峰 on 15/8/18.
 *                 Copyright (c) 2015年 洪峰. All rights reserved.
 *                 新浪微博:http://weibo.com/hongfenglt
 *                 博客地址:http://blog.csdn.net/hongfengkt
 */
//                 CellDownloadImage
//                 Apps.m
//

#import "HFApp.h"

@implementation HFApp

+ (instancetype)appWithDic:(NSDictionary*)dict
{
    HFApp* app = [[self alloc] init];
    [app setValuesForKeysWithDictionary:dict];
    
    return app;
}

@end
