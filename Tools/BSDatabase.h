//
//  BSDatabase.h
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *定义数据库操作类
 */
@interface BSDatabase : NSObject

@property(nonatomic, readonly) long long lastInsertRowId;  //最后一次插入操作的rowid
@property(nonatomic, readonly) int lastModifyCount;        //最后一次操作影响的记录数


//设置SQLITE3的线程访问控制。1:为单线程，2为多线程单数据库打开和语句打开不进行控制，3为序列化操作，支持多线程，默认为2
+(void)setThreadStrategy:(NSInteger)strategy;


//内部调用open,如果打开失败则返回nil
-initWithPath:(NSString*)path;
+(BSDatabase*)dbWithPath:(NSString*)path;


-(BOOL) open:(NSString*)path;
-(void) close;
-(BOOL) isOpen;

//事务处理，在进行多表更新时必须启用事务
-(BOOL) beginTransaction;
-(BOOL) commit;
-(BOOL) rollback;


@end



/*
 *定义SQL语句操作类
 */
/*
 BSDatabase *pDb = [[BSDatabase alloc] init];
 if (![pDb Open:@"/Users/oybq/Documents/Xinhuazh/Local/xinhuatestdata"])
 {
 return 1;
 }
 */

/*
 [BSRecordset Execute:pDb withSql:@"update im_content_info set class_flag='N'"];
 [pDb BeginTransaction];
 
 [BSRecordset Execute:pDb withSql:@"update im_content_info set charge_flag='N'"];
 [pDb Rollback];
 */

/*
 BSRecordset *prec = [BSRecordset RecordsetWithSql:pDb withSql:@"insert into im_StockQuotatCode_dict(zqdm,zqmc,stock_type) values(?,?,?)"];
 [prec SetString:1 Val:@"8888"];
 [prec SetString:2 Val:@"8888"];
 [prec SetString:3 Val:@"aa"];
 
 [prec Execute];
 
 
 [prec SetString:1 Val:@"9999"];
 //[prec SetString:2 Val:@"9999"];
 [prec SetString:3 Val:@"bb"];
 
 [prec Execute];
 */

/*BSRecordset *prec = [BSRecordset RecordsetWithSql:pDb withSql:@"select count(*) from im_StockQuotatCode_dict where stock_type=?"];
 [prec SetString:1 Val:@"SH0A"];
 while (![prec IsEof])
 {
 NSLog(@"the count is:%d\n", [prec GetInt:0]);
 }
 
 [prec Reset];
 [prec SetString:1 Val:@"SZ0D"];
 while (![prec IsEof])
 {
 NSLog(@"the count is:%d\n", [prec GetInt:0]);
 }
 
 [prec Close];
 
 
 
 [pDb release];
 */
@interface BSRecordset : NSObject

@property(nonatomic, readonly) BSDatabase *db;
@property(nonatomic, readonly) int columnCount;   //列的数量

-(id)initWithDB:(BSDatabase*)db;

//打开查询语句，用于执行查询语句，以及带参数的查询语句
-(BOOL)open:(NSString*)sql;
//重设,对于查询操作如果需要换条件查询则调用reset进行重新设置
-(BOOL)reset;
//判断是否打开
-(BOOL)isOpen;
//主要用于查询的遍历.
-(BOOL)isEof;

-(BOOL) execute;
-(BOOL) execute:(BOOL)bClear;
-(void) close;

//列操作
-(NSString*)columnName:(NSInteger)nCol; //根据列得到名字，从0开始。


//列值的设置和获取,设置从1开始，获取从0开始
-(NSString*)stringValue:(NSInteger)nCol;
-(int)intValue:(NSInteger)nCol;
-(long long)longLongValue:(NSInteger)nCol;
-(double)doubleValue:(NSInteger)nCol;
-(NSData*)blobValue:(NSInteger)nCol;

-(void)setString:(NSString*)strVal col:(NSInteger)nCol;
-(void)setInt:(int)iVal col:(NSInteger)nCol;
-(void)setLongLong:(long long)llVal col:(NSInteger)nCol;
-(void)setDouble:(double)dbVal col:(NSInteger)nCol;
-(void)setBlob:(NSData*)blobVal col:(NSInteger)nCol;
-(void)setNull:(NSInteger)nCol;

//清除绑定的值
-(void)clear;

-(NSString*)sql;

//直接单步执行更新，插入，删除语句，用于执行不带参数的语句
+(BOOL)executeWithSql:(BSDatabase*)db withSql:(NSString*)sql;
-(BOOL)executeWithSql:(NSString*)sql;
+(BSRecordset*) recordsetWithDB:(BSDatabase*)db;
+(BSRecordset*) recordsetWithSql:(BSDatabase*)db withSql:sql;


@end


