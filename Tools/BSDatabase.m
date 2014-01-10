//
//  BSDatabase.m
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <sqlite3.h>
//#import <libxml/parser.h>
#import <zlib.h>

#import "BSDatabase.h"



//内部使用。用于对sqlite3的封装
@interface BSDatabase()

-(sqlite3*) database;

@end


@implementation  BSDatabase

sqlite3 *_db;





-(sqlite3*)database
{
    return _db;
}

+(void)setThreadStrategy:(NSInteger)strategy
{
    sqlite3_config(strategy);
}

-(long long)lastInsertRowId
{
    if (_db == NULL)
        return 0;
    
    return sqlite3_last_insert_rowid(_db);
}

-(int)lastModifyCount
{
    if (_db == NULL)
        return 0;
    
    return sqlite3_changes(_db);
}



-init
{
	self = [super init];
	_db = NULL;
	return self;
}

-initWithPath:(NSString*)strPath
{
	self = [self init];
	if (self != nil)
	{
		if (![self open:strPath])
		{
			[self release];
			return nil;
		}
	}
	
	return self;
}



-(BOOL) open:(NSString*)path
{
	if ([self isOpen]) {
		[self close];
	}
	
	return sqlite3_open([path UTF8String], (sqlite3**)&_db) == SQLITE_OK;
}

-(void) close
{
	if ([self isOpen]) {
		sqlite3_close(_db);
		_db = NULL;
	}
}

-(BOOL) isOpen
{
	return _db != NULL;
}


-(BOOL) beginTransaction
{
	return [BSRecordset executeWithSql:self withSql:@"BEGIN"];
}

-(BOOL) commit
{
	return [BSRecordset executeWithSql:self withSql:@"COMMIT"];
}

-(BOOL) rollback
{
	return [BSRecordset executeWithSql:self withSql:@"ROLLBACK"];
}

-(void)dealloc
{
	[self close];
	
	[super dealloc];
}

+(BSDatabase*) dbWithPath:(NSString*)path
{
	return [[[BSDatabase alloc] initWithPath:path] autorelease];
}



@end



/*
 *定义表格操作类
 */
@implementation BSRecordset

void *_stmt;

@synthesize	db;
@synthesize columnCount;

-(id)initWithDB:(BSDatabase*)aDB
{
	self = [super init];
	
	db = [aDB retain];
	_stmt = NULL;
	
	return self;
}


-(BOOL)open:(NSString*)sql
{	
	[self close];
	return sqlite3_prepare_v2([db database], [sql UTF8String], -1, (sqlite3_stmt**)&_stmt, NULL) == SQLITE_OK;
}

-(BOOL)reset
{
	return  sqlite3_reset(_stmt) == SQLITE_OK;
}

-(int)step
{
	return sqlite3_step(_stmt);
}

-(BOOL)isOpen
{
	return _stmt != NULL;
}


-(BOOL)isEof
{
	return [self step] != SQLITE_ROW;
}


-(BOOL) execute
{
	return [self execute:NO];
}

-(BOOL) execute:(BOOL)bClear
{
	if ([self step] != SQLITE_DONE)
		return NO;
	
	[self reset];
	
	if (bClear)
		[self clear];
	
	return YES;
}

-(void)close
{
	if ([self isOpen]) {
		sqlite3_finalize(_stmt);
		_stmt = NULL;
	}
}

-(int)columnCount
{
    return sqlite3_column_count(_stmt);
}

-(NSString*)columnName:(NSInteger)nCol
{
    if (_stmt == NULL) {
        return nil;
    }
    
    return [NSString stringWithCString:sqlite3_column_name16(_stmt, nCol) encoding:NSUnicodeStringEncoding];
}

-(NSString*)stringValue:(NSInteger)nCol
{
	//如果值为空则返回nil;
	char *ptext = (char*)sqlite3_column_text(_stmt, nCol);
	if (ptext == NULL)
	{
		return nil;
	}
	return [NSString stringWithUTF8String:ptext];
}

-(int)intValue:(NSInteger)nCol
{
	return sqlite3_column_int(_stmt,nCol);
}

-(long long)longLongValue:(NSInteger)nCol
{
	return sqlite3_column_int64(_stmt, nCol);
}

-(double)doubleValue:(NSInteger)nCol
{
	return sqlite3_column_double(_stmt, nCol);
}

-(NSData*)blobValue:(NSInteger)nCol
{
	const char *pByte = (const char*)sqlite3_column_blob(_stmt, nCol);
	if (pByte == NULL)
	{
		return nil;
	}
	
	int nLen = sqlite3_column_bytes(_stmt, nCol);
	return [NSData dataWithBytes:pByte length:nLen];
}

-(void)setString:(NSString*)strVal col:(NSInteger)nCol
{
	if (strVal == nil)
		sqlite3_bind_null(_stmt, nCol);
	else
		sqlite3_bind_text(_stmt, nCol, [strVal UTF8String], -1, NULL);
}

-(void)setInt:(int)iVal col:(NSInteger)nCol
{
	sqlite3_bind_int(_stmt, nCol, iVal);
}

-(void)setLongLong:(long long)llVal col:(NSInteger)nCol
{
	sqlite3_bind_int64(_stmt, nCol, llVal);
}

-(void)setDouble:(double)dbVal col:(NSInteger)nCol
{
	sqlite3_bind_double(_stmt, nCol, dbVal);
}

-(void)setBlob:(NSData*)blobVal col:(NSInteger)nCol
{
	if (blobVal == nil)
		sqlite3_bind_null(_stmt, nCol);
	else
		sqlite3_bind_blob(_stmt, nCol, [blobVal bytes], [blobVal length], NULL);
}

-(void)setNull:(NSInteger)nCol
{
	sqlite3_bind_null(_stmt, nCol);
}

-(void)clear
{
	sqlite3_clear_bindings(_stmt);
}


-(NSString*)sql
{
	return [[[NSString alloc ] initWithUTF8String:sqlite3_sql(_stmt)] autorelease];
}


//单步执行更新，插入，删除语句，用于执行不带参数的语句
+(BOOL)executeWithSql:(BSDatabase*)db withSql:(NSString*)sql
{
	return sqlite3_exec([db database], [sql UTF8String], NULL, NULL, NULL) == SQLITE_DONE;
}

-(BOOL)executeWithSql:(NSString*)sql
{
	return  sqlite3_exec([db database], [sql UTF8String], NULL, NULL, NULL) == SQLITE_DONE;
}



+(BSRecordset*) recordsetWithDB:(BSDatabase*)db
{
	return [[[BSRecordset alloc] initWithDB:db] autorelease];
}

+(BSRecordset*) recordsetWithSql:(BSDatabase*)db withSql:strSql
{
	BSRecordset *p = [[BSRecordset alloc] initWithDB:db];
	if (![p open:strSql])
	{
		[p release];
		return nil;
	}
	
	return [p autorelease];
}




-(void)dealloc
{
	[self close];
	[db release];
	[super dealloc];
}



@end

