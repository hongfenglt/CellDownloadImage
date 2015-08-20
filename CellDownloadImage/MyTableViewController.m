/**
 *                 Created by 洪峰 on 15/8/18.
 *                 Copyright (c) 2015年 洪峰. All rights reserved.
 *
 *                 新浪微博:http://weibo.com/hongfenglt
 *                 博客地址:http://blog.csdn.net/hongfengkt
 */
//                 CellDownloadImage
//                 MyTableViewController.m
//

#define HFAppImageFile(url) [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[url lastPathComponent]]

#import "MyTableViewController.h"
#include "HFApp.h"
@interface MyTableViewController ()
/**
 *  所有应用数据
 */
@property (nonatomic,strong) NSMutableArray* apps;

/**
 *  存放所有下载操作的队列
 */
@property (nonatomic,strong) NSOperationQueue* queue;

/**
 *  存放所有的下载操作（url是key，operation对象是value）
 */
@property (nonatomic,strong) NSMutableDictionary* operations;
/**
 *  存放所有下载完成的图片，用于缓存
 */
@property (nonatomic,strong) NSMutableDictionary* images;
@end

@implementation MyTableViewController

#pragma mark ---getters And setters
- (NSMutableArray *)apps
{
    if (nil == _apps) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"apps.plist" ofType:nil];
        NSArray* dictArr = [NSArray arrayWithContentsOfFile:filePath];
        
        NSMutableArray* appsArr = [NSMutableArray array];
        for (NSDictionary* dict in dictArr) {
            
            HFApp* app = [HFApp appWithDic:dict];
            
            [appsArr addObject:app];
        }
        self.apps = appsArr;
    }
    return _apps;
}

- (NSOperationQueue *)queue
{
    if (!_queue) {
        self.queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (NSMutableDictionary *)operations
{
    if (nil == _operations) {
        
        self.operations = [NSMutableDictionary dictionary];
    }
    return _operations;
}

- (NSMutableDictionary *)images
{
    if (nil == _images) {
        self.images = [NSMutableDictionary dictionary];
    }
    return _images;
}

#pragma mark ---life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
     NSLog(@"沙盒路径: %@",NSHomeDirectory());
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    //内存警告时
    // 移除所有的下载操作缓存
    [self.queue cancelAllOperations];
    [self.operations removeAllObjects];
    // 移除所有的图片缓存
    [self.images removeAllObjects];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.apps.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifer = @"apps";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
    }
    //取出数据
    HFApp* app = self.apps[indexPath.row];
    cell.textLabel.text = app.name;
    cell.detailTextLabel.text = app.download;
    
    // 先从images缓存中取出图片url对应的UIImage
    UIImage *image = self.images[app.icon];
    
    if (image) {//成功缓存过
        
        cell.imageView.image = image;
        
    }else{ //缓存中没有图片
        
//        
//        NSString* CachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
//        NSString* filePath = [CachesPath stringByAppendingPathComponent:[app.icon lastPathComponent]];
//        NSData* ImgaeData = [NSData dataWithContentsOfFile:filePath];
        
        // 获得caches的路径, 拼接文件路径
         NSString *filePath = HFAppImageFile(app.icon);
         NSData* ImgaeData = [NSData dataWithContentsOfFile:filePath];
        if (ImgaeData) { // 缓存中有图片
            cell.imageView.image = [UIImage imageWithData:ImgaeData];
        }else{ // 缓存中没有图片，需要下载

            // 显示占位图片
            cell.imageView.image = [UIImage imageNamed:@"placeholder"];
            //到子线程执行下载操作
            //取出当前URL对应的下载下载操作
            NSBlockOperation* operation = self.operations[app.icon];
            if (nil == operation) {
                //创建下载操作
                __weak typeof(self) vc = self;
                operation = [NSBlockOperation blockOperationWithBlock:^{
                    
                    NSURL* url = [NSURL URLWithString:app.icon];
                    NSData* data =  [NSData dataWithContentsOfURL:url];
                    UIImage* image = [UIImage imageWithData:data];
                    
                    //下载完成的图片放入缓存字典中
                    if (image) { //防止下载失败为空赋值造成崩溃
                        vc.images[app.icon] = image;
                        
                        //下载完成的图片存入沙盒中
                        
                        // UIImage --> NSData --> File（文件）
                        NSData* ImageData = UIImagePNGRepresentation(image);
            
                        [ImageData writeToFile:HFAppImageFile(app.icon) atomically:YES];
                    }
                    
                    //回到主线程刷新表格
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                        // 从字典中移除下载操作 (防止operations越来越大，保证下载失败后，能重新下载)
                        [vc.operations removeObjectForKey:app.icon];
                        
                        //刷新当前行的图片数据
                        [vc.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }];
                }];
                //添加操作到队列中
                [self.queue addOperation:operation];
                //添加到字典中
                self.operations[app.icon] = operation;

        }
        }
    }

    
    return cell;
}
/**
 *  当用户开始拖拽表格时调用
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // 暂停下载
    [self.queue setSuspended:YES];
}

/**
 *  当用户停止拖拽表格时调用
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // 恢复下载
    [self.queue setSuspended:NO];
}







































@end
