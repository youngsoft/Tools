//
//  BSCompress.h
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 *功能：实现系统的压缩和解压缩zlib和gzip的压缩和解压缩
 */
@interface BSCompression : NSObject {
	
}

//解压缩,nFlag设置属性，默认为0表示zlib压缩，1表示gzip压缩
+(NSData*) Extract:(NSData*)ripeData Flag:(int)nFlag;
+(NSData*) Compress:(NSData*)rawData Flag:(int)nFlag;


@end

