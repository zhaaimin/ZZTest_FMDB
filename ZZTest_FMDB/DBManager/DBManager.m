//
//  DBManager.m
//  ZZTest_FMDB
//
//  Created by itp on 16/6/29.
//  Copyright © 2016年 zte. All rights reserved.
//

#import "DBManager.h"

static NSString* imDBName = @"/ZZFMDBDB";
static FMDatabase *dbHandle=nil;
static FMDatabaseQueue* globalDatabaseQueue = nil;

@implementation DBManager

static NSString *documentDir = nil;

#pragma mark - 数据库

+ (BOOL)initDB
{
    return [self checkDocumentDir];
}

+ (BOOL)checkDocumentDir
{
    if (!documentDir)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentDir = paths[0];
    }
    
    if (!documentDir || [documentDir length] == 0)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

+ (NSString *)getDocumentDir
{
    NSString *documentStr = documentDir;
    return documentStr;
}

+ (BOOL)createDBWithName:(NSString *)dbName
{
    if (![self checkDocumentDir])
    {
        return FALSE;
    }
    
    return TRUE;
}

#pragma mark - 表

+ (BOOL)createTable:(NSString *)tableName withColumn:(NSString *)columnStr inDBOfName:(NSString *)dbName
{
    if ([self createDBWithName:dbName])
    {
        FMDatabase *tempDB = [DBManager getDBHandle];
        if (tempDB == nil)
        {
            return FALSE;
        }
        
        NSString *sql = [@"create table " stringByAppendingString:tableName];
        sql = [sql stringByAppendingString:columnStr];
        BOOL result = [tempDB executeUpdate:sql];
        
        /*创建索引
        NSString *createTimeIndex=@"CREATE INDEX tim_index ON message(time)";
        NSString *createMsgidIndex=@"CREATE INDEX msgid_index ON message(msgid)";
        [tempDB executeUpdate:createTimeIndex];
        [tempDB executeUpdate:createMsgidIndex];
         */
        return result;
    }
    
    return FALSE;
}

+ (BOOL)createTableForQueue:(NSString *)tableName withColumn:(NSString *)columnStr inDBOfName:(NSString *)dbName
{
    if ([self createDBWithName:dbName])
    {
        FMDatabaseQueue *myQueue = [self getDatabaseQueue];
        
        __block BOOL result;
        
        [myQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
           
            NSString *sql = [@"create table " stringByAppendingString:tableName];
            sql = [sql stringByAppendingString:columnStr];
            result = [db executeUpdate:sql];
        }];
    
        /*创建索引
         NSString *createTimeIndex=@"CREATE INDEX tim_index ON message(time)";
         NSString *createMsgidIndex=@"CREATE INDEX msgid_index ON message(msgid)";
         [tempDB executeUpdate:createTimeIndex];
         [tempDB executeUpdate:createMsgidIndex];
         */
        return result;
    }
    
    return FALSE;
}

+ (BOOL)initCheckTable:(NSString*)tableName existInDBOfName:(NSString*)dbName
{
    NSString* sql = @"select count(*) as c from Sqlite_master where type = 'table' and name = '";
    sql = [sql stringByAppendingString:tableName];
    sql = [sql stringByAppendingString:@"'"];
    
    FMDatabase* tempDB = [DBManager getDBHandle];
    if (tempDB==Nil)
    {
        return FALSE;
    }
    FMResultSet* rs = [tempDB executeQuery:sql];
    if([rs next])
    {
        int userId = [rs intForColumn:@"c"];
        
        /*如果和Queues并用，需要关闭
        [rs close];
        [tempDB close];
         */
        
        if(userId > 0)
        {
            return TRUE;
        }else
        {
            return FALSE;
        }
    }
    return FALSE;
}

+ (BOOL)initCheckTableForQueue:(NSString *)tableName existInDBOfName:(NSString *)dbName
{
    FMDatabaseQueue *myQueue = [self getDatabaseQueue];
    
    __block BOOL result = NO;
    
    if (!myQueue) return NO;
    
    [myQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        NSString* sql = @"select count(*) as c from Sqlite_master where type = 'table' and name = '";
        sql = [sql stringByAppendingString:tableName];
        sql = [sql stringByAppendingString:@"'"];
        
        FMResultSet* rs = [db executeQuery:sql];
        if ([rs next])
        {
            int userId = [rs intForColumn:@"c"];
            
            result = (userId > 0);
        }

    }];
    
    return result;
}

+ (BOOL)deleteTable:(NSString *)tableName existInDBOfName:(NSString *)dbName
{
    if(![self initCheckTable:tableName existInDBOfName:imDBName])
    {
        return TRUE;
    }
    
    FMDatabase* tempDB = [DBManager getDBHandle];
    
    if (tempDB==Nil)
    {
        return FALSE;
    }
    
    NSString* sql = @"drop table '";
    sql = [sql stringByAppendingString:tableName];
    sql = [sql stringByAppendingString:@"'"];
    
    BOOL res = [tempDB executeUpdate:sql];
    return res;
}

+ (BOOL)updateTable:(NSString *)tableName updateSql:(NSString *) sql
{
    if (![DBManager initCheckTable:tableName existInDBOfName:imDBName])
    {
        return NO;
    }
    
    FMDatabase* tempDB = [DBManager getDBHandle];
    if (tempDB==Nil) return NO;
    
    BOOL res = NO;
    
    res = [tempDB executeUpdate:sql];
    
    return res;
}

#pragma mark - 打开数据库
/**
 *  整个APP声明周期只打开一次数据库，退出的时候关闭
 */
+ (FMDatabase *)getDBHandle
{
    if (dbHandle != nil)
    {
        return dbHandle;
    }
    dbHandle = [FMDatabase databaseWithPath:[documentDir stringByAppendingString:imDBName]];
    if ([dbHandle open])
    {
        /*
        int result = [DBManager SetDbKeyforDB:dbHandle];
        if (result < 0)
        {
            return nil;
        }
        */
    }
    
    return dbHandle;
}

+ (FMDatabaseQueue * )getDatabaseQueue
{
    if (globalDatabaseQueue != nil)
    {
        return globalDatabaseQueue;
    }
    
    globalDatabaseQueue = [FMDatabaseQueue databaseQueueWithPath:[documentDir stringByAppendingPathComponent:imDBName]];
    
    return globalDatabaseQueue;
}

#pragma mark 设置DB key, 如果无key，则生成一个，如果有， 则暂时donothing， 如果原来的Key校验失败，则返回
/**
 *  根据DB的句柄，设置DB key， 返回值， > 0 表示okay, < 0表示校验不通过
 */

//错误码使用： 0 --无key， -1， db不存在， -2， key校验失败 1，校验成功
//2， 设置Key成功 -3， 设置Key失败
+ (int) SetDbKeyforDB:(FMDatabase* )dbHandle
{
    int res=-1;
    //首先进行 Key校验，这是任何DB操作都要进行的
    NSString *Key = [[NSUserDefaults standardUserDefaults] objectForKey:@"DB_Key"];;
    
    //如果key无值，则认为成功， 即使key丢失的情况，也算成功
    if(YES == [Key isEqualToString:@""] || nil == Key)
    {
        res = 0;
    }
    else
    {
        //校验成功，则返回成功
        if([dbHandle setKey:Key])
        {
            res = 1;
        }
        else
        {
            res = -2;
        }
    }
    
    //校验失败， 可能是key错误导致的， 保守的处理，应该删除当前DB，重新生成，但暂时不这么做
    if(res < 0)
    {
        //donothing
    }
    //key无值，则需要重新设置
    else if(res == 0)
    {
        //gene Key,
        NSString * Key = @"AE03A65F-D0F3-44EC-B2C7-EE64DE20E394";
        
        //设置成功，则保存key， 返回成功
        if([dbHandle setKey:Key])
        {
            [[NSUserDefaults standardUserDefaults] setObject:Key forKey:@"DB_Key"];
            
            res = 2;
        }
        //失败，则有可能是因为，DB存在key，但由于本地丢失了Key，导致设置失败，保守的处理，应该删除当前DB，重新生成，但暂时不这么做
        else
        {
            res = -3;
        }
    }
    //有值， 且检查成功， 可什么都不做，也可以重新设置
    else
    {
        //donothing now
    }
    return res;
}

+ (BOOL)checkColumnExsit:(NSString *)columnName inTable:(NSString *)tableName
{
    if(!columnName || !tableName) return NO;
    
    if(!tableName) return NO;
    
    if (![DBManager initCheckTable:tableName existInDBOfName:imDBName]) return NO;
    
    FMDatabase* tempDB = [DBManager getDBHandle];
    
    if (tempDB == Nil) return NO;
    
    return [tempDB columnExists:columnName inTableWithName:tableName];
}

+ (BOOL)insertToTableWithColumnName:(NSString *)columnName inInTable:(NSString *)tableName
{
    NSString *sql = nil;
    BOOL result = NO;
    
    sql = [NSString stringWithFormat: @"alter table %@ add column %@ long long DEFAULT '';",tableName,columnName];
    result = [self updateTable:tableName updateSql:sql];

    return result;
}

#pragma mark - 表数据操作

//更新数据
+ (BOOL)updateRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName;
{
    FMDatabase* tempDB = [DBManager getDBHandle];
    if (tempDB==Nil)
    {
        return FALSE;
    }
    
    BOOL result = [tempDB executeUpdate:sql];
    return result;
}

//插入数据
+ (BOOL)insertRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName
{
    return [self updateRecordWithSql:sql inDBName:dbName];
}

//删除数据
+ (BOOL)deleteRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName;
{
    return [self updateRecordWithSql:sql inDBName:dbName];
}

//查询数据
+ (BOOL)queryRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName
{
    FMDatabase* tempDB = [DBManager getDBHandle];
    if (tempDB == Nil)
    {
        return FALSE;
    }

    FMResultSet * rs = [tempDB executeQuery:sql];
    if([rs next])
    {
        return TRUE;
    }
    
    return FALSE;
}

//批量插入数据
+ (int)insertRecordWithSqls:(NSMutableArray *)sqls inDBName:(NSString *)dbName
{
    return [self updateRecordWithSqls:sqls inDBName:dbName];
}

//批量删除数据
+ (int)deleteRecordWithSqls:(NSMutableArray *)sqls inDBName:(NSString *)dbName
{
    return [self updateRecordWithSqls:sqls inDBName:dbName];
}

+ (FMResultSet *)queryRecordWithSqls:(NSMutableArray *)sqls inDBName:(NSString *)dbName
{
    FMDatabaseQueue *myQueue = [self getDatabaseQueue];
    if (!myQueue) return FALSE;
    
    __block FMResultSet *result = nil;
    
    [myQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (NSString *sql in sqls)
        {
            FMResultSet *re = [db executeQuery:sql];
            
            result = re;
        }
    }];
    
    return result;
}

//批量更新数据
+ (int)updateRecordWithSqls:(NSMutableArray*)sqls inDBName:(NSString*)dbName
{
    FMDatabaseQueue* myQueue = [self getDatabaseQueue];

    if(!myQueue)
    {
        return FALSE;
    }
    
    __block int successCount = 0;
    
    [myQueue inTransaction:^(FMDatabase* myDB, BOOL* rollback){
        
        for(NSString *sql in sqls)
        {
            if(sql)
            {
                if([myDB executeUpdate:sql])
                {
                    successCount++;
                }
            }
        }
    }];
    
    return successCount;
}

+ (int)insertToTable:(NSString *)tableName withColumn:(NSString *)columnNames withParamArray:(NSMutableArray *)paramArray inDBOfName:(NSString *)dbName
{
    FMDatabaseQueue* myQueue = [self getDatabaseQueue];
    
    if(!myQueue) return FALSE;
    
    __block int successCount = 0;
    
    [myQueue inTransaction:^(FMDatabase* myDB, BOOL* rollback){
        
        NSString* sqlHead = [@"insert into " stringByAppendingString:tableName];
        sqlHead = [sqlHead stringByAppendingString:columnNames];
        sqlHead = [sqlHead stringByAppendingString:@" values "];
        
        for(NSString *tempParam in paramArray)
        {
            if(tempParam)
            {
                if([myDB executeUpdate:[sqlHead stringByAppendingString:tempParam]])
                {
                    successCount++;
                }
            }
        }
    }];
    
    return successCount;
}
@end
