//
//  DBManager.h
//  ZZTest_FMDB
//
//  Created by itp on 16/6/29.
//  Copyright © 2016年 zte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface DBManager : NSObject

#pragma mark - 数据库

//初始化数据库
+ (BOOL)initDB;
+ (BOOL)checkDocumentDir;
+ (NSString *)getDocumentDir;

//创建数据库
+ (BOOL)createDBWithName:(NSString *)dbName;

#pragma mark - 表

//在数据库中创建表
+ (BOOL)createTable:(NSString *)tableName withColumn:(NSString *)columnStr inDBOfName:(NSString *)dbName;
+ (BOOL)createTableForQueue:(NSString *)tableName withColumn:(NSString *)columnStr inDBOfName:(NSString *)dbName;

//检测表是否存在
+ (BOOL)initCheckTable:(NSString *)tableName existInDBOfName:(NSString *)dbName;
+ (BOOL)initCheckTableForQueue:(NSString *)tableName existInDBOfName:(NSString *)dbName;

//删除某一张表
+ (BOOL)deleteTable:(NSString *)tableName existInDBOfName:(NSString *)dbName;

//检测表中是否存在某一列
+ (BOOL)checkColumnExsit:(NSString *)columnName inTable:(NSString *)tableName;

//向某张表中新增列
+ (BOOL)insertToTableWithColumnName:(NSString *)columnName inInTable:(NSString *)tableName;

//向某张表中新增列
+ (int)insertToTable:(NSString *)tableName withColumn:(NSString *)columnNames withParamArray:(NSMutableArray *)paramArray inDBOfName:(NSString *)dbName;

//更新表
+ (BOOL)updateTable:(NSString *)tableName updateSql:(NSString *)sql;

#pragma mark - 表数据操作

/**
 * 单条记录操作
 **/

+ (BOOL)insertRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName;

+ (BOOL)updateRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName;

+ (BOOL)deleteRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName;

+ (BOOL)queryRecordWithSql:(NSString *)sql inDBName:(NSString *)dbName;

/**
 * 批量操作
 **/

+ (int)insertRecordWithSqls:(NSMutableArray *)sqls inDBName:(NSString *)dbName;

+ (int)updateRecordWithSqls:(NSMutableArray *)sqls inDBName:(NSString *)dbName;

+ (int)deleteRecordWithSqls:(NSMutableArray *)sqls inDBName:(NSString *)dbName;

+ (FMResultSet *)queryRecordWithSqls:(NSMutableArray *)sqls inDBName:(NSString *)dbName;
@end
