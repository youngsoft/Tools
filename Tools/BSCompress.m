//
//  BSCompress.m
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <zlib.h>

#import "BSCompress.h"




@implementation BSCompression

+(NSData*)zlibExtract:(NSData*)ripeData
{
    
	int nOutBufLen = [ripeData length];
	Byte *pOutBuf = (Byte*)malloc(nOutBufLen);
	if (pOutBuf == nil)
	{
		return nil;
	}
	
	
	z_stream zstrm;
	memset(&zstrm, 0, sizeof(zstrm));
	zstrm.avail_in = nOutBufLen;
	zstrm.next_in = (void*)[ripeData bytes];
    int ret = inflateInit(&zstrm);
    if (ret != Z_OK)
	{
		free(pOutBuf);
		return nil;
	}
	
	//分配输出缓存
	
	NSMutableData  *rawData = [NSMutableData dataWithCapacity:nOutBufLen];
	do
	{
		zstrm.avail_out = nOutBufLen;
		zstrm.next_out = pOutBuf;
		switch (inflate(&zstrm, Z_NO_FLUSH))
		{
			case Z_NEED_DICT:
			case Z_STREAM_ERROR:
			case Z_DATA_ERROR:  // zlib 流格式错误
			case Z_MEM_ERROR:   // inflate() 分配内存失败
			{
				free(pOutBuf);
				inflateEnd(&zstrm);
				return nil;
				break;
			}
		}
		
		[rawData appendBytes:pOutBuf length:nOutBufLen - zstrm.avail_out];
	} while(zstrm.avail_out == 0);
	
	inflateEnd(&zstrm);
	free(pOutBuf);
	
	return rawData;
    
}

+(NSData*)gzipExtract:(NSData*)ripeData
{
    //gzip头10字节+ 压缩数据 + 4字节CRC校验 + 4字节原始长度
    
    int ripeDataLen = ripeData.length;
    unsigned char *ripeDataBytes = (unsigned char*)ripeData.bytes;
    
    if (ripeDataLen < 18)
        return nil;
    
    //判断是否是以1f 8b开头的。如果不是则返回错误。
    if (ripeDataBytes[0] != 0x1f && ripeDataBytes[1] != 0x8b)
        return nil;
    
    
    //最后4个字节是原始数据的长度, 分配输出缓存。
    int rawDataLen = *((int*)(ripeDataBytes + ripeDataLen - 4)) ;
	Byte *rawDataBytes = (Byte*)malloc(rawDataLen);
	if (rawDataBytes == nil)
	{
		return nil;
	}
	
	
	z_stream zstrm;
	memset(&zstrm, 0, sizeof(zstrm));
	zstrm.avail_in = ripeDataLen - 18; //不考虑gzip头和后面8个字节的校验和原始长度。
	zstrm.next_in = ripeDataBytes + 10; //跳过gzip头
    
    //-15表示内容中包括的是原始的压缩内容。
    int ret = inflateInit2(&zstrm, -15);
    if (ret != Z_OK)
	{
		free(rawDataBytes);
		return nil;
	}
    
    zstrm.avail_out = rawDataLen;
    zstrm.next_out = rawDataBytes;
    ret = inflate(&zstrm, Z_FINISH);
    switch (ret)
    {
        case Z_NEED_DICT:
        case Z_STREAM_ERROR:
        case Z_DATA_ERROR:  // zlib 流格式错误
        case Z_MEM_ERROR:   // inflate() 分配内存失败
        {
            free(rawDataBytes);
            inflateEnd(&zstrm);
            return nil;
            break;
        }
    }
	
    //做CRC校验。
    int crc = crc32(0, rawDataBytes, rawDataLen);
    if (crc != *((int*)(ripeDataBytes + ripeDataLen - 8)))
    {
        free(rawDataBytes);
        inflateEnd(&zstrm);
        return nil;
    }
    
	NSData *rawData = [NSData dataWithBytes:rawDataBytes length:rawDataLen];
	inflateEnd(&zstrm);
	free(rawDataBytes);
	
	return rawData;
    
}

//压缩和解压缩
+(NSData*) Extract:(NSData*)ripeData Flag:(int)nFlag
{
    
    if (ripeData == nil) {
		return nil;
	}
	
    if (nFlag == 0)
        return [self zlibExtract:ripeData];
    else
        return [self gzipExtract:ripeData];
    
}

+(NSData*)zlibCompress:(unsigned char*)rawData rawDataLen:(NSInteger)rawDataLen ripeData:(unsigned char*)ripeData ripeDataLen:(unsigned long)ripeDataLen
{
    /*
     zlib格式：
     zlib头+deflate(rawData)+rawData的CRC校验+rawDataLen
     */
    if(compress(ripeData, &ripeDataLen, (void*)rawData, rawDataLen) != Z_OK)
	{
		free(ripeData);
		return nil;
	}
	
	return [NSData dataWithBytesNoCopy:ripeData length:ripeDataLen];
}

+(NSData*)gzipCompress:(unsigned char*)rawData rawDataLen:(NSInteger)rawDataLen ripeData:(unsigned char*)ripeData ripeDataLen:(NSInteger)ripeDataLen
{
    /*
     gzip格式如下：
     gzip头+deflate(rawData)+rawData的CRC校验+rawDataLen
     */
    
    //先写入头。
    sprintf((char*)ripeData, "%c%c%c%c%c%c%c%c%c%c", 0x1f, 0x8b,
            Z_DEFLATED, 0 /*flags*/, 0,0,0,0 /*time*/, 0 /*xflags*/, 3);
    
    
    z_stream zstrm;
	memset(&zstrm, 0, sizeof(zstrm));
	zstrm.avail_in = rawDataLen;
	zstrm.next_in = rawData;
    zstrm.avail_out = ripeDataLen - 10;
    zstrm.next_out = ripeData + 10;
    
    //-15表示直接deflate压缩不会加上zlib头和尾部
    int ret = deflateInit2(&zstrm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY);
    if (ret != Z_OK)
    {
        free(ripeData);
        return nil;
    }
    
    ret = deflate(&zstrm, Z_FINISH);
    if (ret != Z_STREAM_END)
    {
        free(ripeData);
        deflateEnd(&zstrm);
        return nil;
    }
    
    deflateEnd(&zstrm);
    
    
    //计算校验并写入。
    int crc = crc32(0, rawData, rawDataLen);
    memcpy(ripeData + 10 + zstrm.total_out, &crc, 4);
    memcpy(ripeData + 10 + zstrm.total_out + 4, &rawDataLen, 4);
    ripeDataLen = zstrm.total_out + 10 + 8;
    
    return [NSData dataWithBytesNoCopy:ripeData length:ripeDataLen];
}


+(NSData*) Compress:(NSData*)rawData Flag:(int)nFlag
{
	if (rawData == nil) {
		return nil;
	}
	
	unsigned long compressLen =compressBound([rawData length]) + 100;
	unsigned char *pRipeData = (unsigned char*)malloc(compressLen);
	if (pRipeData == NULL) {
		return nil;
	}
    
    if (nFlag == 0)
        return [self zlibCompress:(unsigned char*)rawData.bytes rawDataLen:rawData.length ripeData:pRipeData ripeDataLen:compressLen];
    else
        return [self gzipCompress:(unsigned char*)rawData.bytes rawDataLen:rawData.length ripeData:pRipeData ripeDataLen:compressLen];
    
}

@end
