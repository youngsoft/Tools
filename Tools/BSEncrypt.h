//
//  BSEncrypt.h
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 实现3DES的加密和解密功能，
 */

@interface BS3DES : NSObject

//随机得到一个3DES秘钥
+(NSData*)key;

+(NSData*)encrypt:(NSData*)rawData withKey:(NSData*)key;
+(NSData*)decrypt:(NSData*)ripeData withKey:(NSData*)key;

@end

