//
//  AppDelegate.m
//  ZZTest_FMDB
//
//  Created by itp on 16/6/29.
//  Copyright © 2016年 zte. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)createTestTable
{
    /*
    if ([DBManager initCheckTable:@"testTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        return;
    }

    [DBManager createTable:@"testTable" withColumn:columnStr inDBOfName:@"/ZZFMDBDB"];
    */
    
    if ([DBManager initCheckTableForQueue:@"testTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        return;
    }
    
    NSString* columnStr = @"('id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 'data_owner' TEXT,'userUri' text, 'chatRoomUri' text, 'sendUri' text, 'sendName' text, 'content' text, 'msgid' text, 'msgType' integer,'seq' integer)";
    
    [DBManager createTableForQueue:@"testTable" withColumn:columnStr inDBOfName:@"/ZZFMDBDB"];
    
}

- (void)createOtherTable
{
    if ([DBManager initCheckTable:@"otherTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        return;
    }
    
    NSString* columnStr = @"('a' integer)";
    
    [DBManager createTable:@"otherTable" withColumn:columnStr inDBOfName:@"/ZZFMDBDB"];
}

- (void)insertRecord:(void (^)())success
{
    if ([DBManager initCheckTable:@"testTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        NSString *sql = [NSString stringWithFormat:@"insert into testTable (data_owner,userUri, chatRoomUri, sendUri, sendName, content, msgId, msgType,seq) values ('%@', '%@', '%@', '%@', '%@', '%@', '%@', %d,%d)",
                         @"ZZ",
                         @"Zam",
                         @"102012",
                         @"Wangli",
                         @"查查",
                         @"测试测试测试",
                         @"100",
                         1,
                         1000
                         ];
        
        BOOL result = [DBManager insertRecordWithSql:sql inDBName:@"/ZZFMDBDB"];
        
        if (result)
        {
            NSLog(@"插入数据成功");
        }
    }
}

- (void)insertRecords
{
    if ([DBManager initCheckTableForQueue:@"testTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        NSMutableArray *sqls = [NSMutableArray arrayWithCapacity:10];
        
        for (int i = 0; i < 1000; i ++)
        {
            NSInteger seq = 1000 + i;
            
            NSString *msgId = [NSString stringWithFormat:@"%d",(100 + i)];
            
            NSString *sql = [NSString stringWithFormat:@"insert into testTable (data_owner,userUri, chatRoomUri, sendUri, sendName, content, msgId, msgType,seq) values ('%@', '%@', '%@', '%@', '%@', '%@', '%@', %d,%ld)",
                             @"ZZ",
                             @"Zam",
                             @"102012",
                             @"Wangli",
                             @"查查",
                             @"测试测试测试",
                             msgId,
                             1,
                             (long)seq
                             ];
            
            [sqls addObject:sql];
        }
        
        int allSuccess = [DBManager insertRecordWithSqls:sqls inDBName:@"/ZZFMDBDB"];
        
        NSLog(@"插入成功了%d条数据",allSuccess);
    }
}

- (void)insertRecordsNoQueue
{
    if ([DBManager initCheckTable:@"transtest" existInDBOfName:@"/ZZFMDBDB"])
    {
        for (int i = 0; i < 1000; i ++)
        {
            NSString *sql = [NSString stringWithFormat:@"insert into transtest values (3)"];
            
            BOOL result = [DBManager insertRecordWithSql:sql inDBName:@"/ZZFMDBDB"];
            
            if (result)
            {
                NSLog(@"插入数据成功");
            }
        }
    }
}

- (void)updateRecord
{
    
}

- (void)saveRecordWithSuccess:(void (^)())success
{
    if ([DBManager initCheckTable:@"testTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        //判断数据是否存在
        NSString *checkSql = [NSString stringWithFormat:@"Select * from testTable where msgId = '%@'",@"101"];
        
        BOOL result = [DBManager queryRecordWithSql:checkSql inDBName:@"/ZZFMDBDB"];
        
        if (result)
        {
            //1.存在-更新数据
            NSLog(@"存在这条消息");
        }
        else
        {
            //2.不存在-插入数据
            NSLog(@"不存在这条消息");
            [self updateRecord];
        }
    }
    else
    {
        //表不存在
        return;
    }
}

- (void)upgradeTestTable
{
    BOOL res = NO;
    
    if (![DBManager initCheckTable:@"testTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        return;
    }
    
    if(![DBManager checkColumnExsit:@"seq" inTable:@"testTable"])
    {
        res = [DBManager insertToTableWithColumnName:@"seq" inInTable:@"testTable"];;
        
        if (!res)
        {
            NSLog(@"seq 字段新增失败");
        }
        else
        {
            NSLog(@"seq 字段新增成功");
        }
    }
    else
    {
        NSLog(@"seq 字段已存在");
    }
}

- (void)queryRecords
{
    if ([DBManager initCheckTableForQueue:@"testTable" existInDBOfName:@"/ZZFMDBDB"])
    {
        /*
         SELECT * FROM table LIMIT 20,10;  // 检索记录行 21-30
         
         //为了检索从某一个偏移量到记录集的结束所有的记录行，可以指定第二个参数为 -1：
         SELECT * FROM table LIMIT 95,-1; // 检索记录行 96-last.
         
         //如果只给定一个参数，它表示返回最大的记录行数目：
         SELECT * FROM table LIMIT 5;     //检索前 5 个记录行
         
         //换句话说，LIMIT n 等价于 LIMIT 0,n
         */
        
        NSString *querySql = [NSString stringWithFormat:@"Select * from testTable where seq < 1010 order by msgId desc limit 2,-1"];
        
        NSMutableArray *sqls = [NSMutableArray arrayWithCapacity:17];
        [sqls addObject:querySql];
        
        FMResultSet *result = [DBManager queryRecordWithSqls:sqls inDBName:@"/ZZFMDBDB"];
        
        while ([result next])
        {
            NSLog(@"msgId = %@,content = %@",[result stringForColumn:@"msgId"],[result stringForColumn:@"content"]);
        }
    }
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    [DBManager initDB];
    [DBManager createDBWithName:@"/ZZFMDBDB"];
    
    [self createTestTable];
    
//    [self saveRecordWithSuccess:nil];
//    
//    [self upgradeTestTable];
    
//    [self createOtherTable];
    
//    [self insertRecord:nil];

    [self insertRecords];
    
//    [self insertRecordsNoQueue];
    
    [self queryRecords];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
