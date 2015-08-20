/**
 *
 *                 Created by 洪峰 on 15/8/18.
 *                 Copyright (c) 2015年 洪峰. All rights reserved.
 *
 *                 新浪微博:http://weibo.com/hongfenglt
 *                 博客地址:http://blog.csdn.net/hongfengkt
 */
//                 CellDownloadImage
//                 Apps.h
//


#import <Foundation/Foundation.h>

@interface HFApp : NSObject
/**
 *  应用的名字
 */
@property (nonatomic ,copy)NSString *name;

@property (nonatomic ,copy)NSString *download;
/**
 *  图片url
 */
@property (nonatomic ,copy)NSString *icon;

+ (instancetype)appWithDic:(NSDictionary*)dict;

@end

