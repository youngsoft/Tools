//
//  BSEncrypt.m
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <Security/Security.h>
#include <CommonCrypto/CommonCrypto.h>
#import "BSEncrypt.h"



@implementation BS3DES

//得到3DES加密的秘钥，秘钥在系统启动的时候自动生成。
+(NSData*)key
{
    
    NSData *retKey = nil;
    
    //生成一个3DESkey
    uint8_t * symmetricKey  = malloc( kCCKeySize3DES * sizeof(uint8_t) );
    memset((void *)symmetricKey, 0x0, kCCKeySize3DES);
    if (SecRandomCopyBytes(kSecRandomDefault, kCCKeySize3DES, symmetricKey) == 0)
    {
        retKey = [NSData dataWithBytes:(const void *)symmetricKey length:kCCKeySize3DES];
        
        
    }
    free(symmetricKey);
    
    return retKey;
    
}



+(NSData*)dealData:(NSData*)plainData context:(CCOperation)encryptOrDecrypt padding:(CCOptions)pkcs7 withKey:(NSData*)key
{
    if (plainData == nil)
        return nil;
    
    NSData *retData = nil;
    size_t movedBytes = 0;
    size_t bufferSize = ([plainData length] + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    uint8_t *buffer = malloc( bufferSize * sizeof(uint8_t));
    memset((void *)buffer, 0x0, bufferSize);
    
    CCCryptorStatus ccStatus = CCCrypt(encryptOrDecrypt,
                                       kCCAlgorithm3DES,
                                       pkcs7,
                                       key.bytes, //"123456789012345678901234", //key
                                       kCCKeySize3DES,
                                       "12345678",  //"init Vec", //"init Vec", //iv,
                                       [plainData bytes], //"Your Name", //plainText,
                                       [plainData length],
                                       (void *)buffer,
                                       bufferSize,
                                       &movedBytes);
    
    if (ccStatus == kCCSuccess)
    {
        retData = [NSData dataWithBytes:(const void *)buffer length:(NSUInteger)movedBytes];
    }
    
    free(buffer);
    return retData;
}


+(NSData*)encrypt:(NSData*)rawData withKey:(NSData*)key
{
    return [self dealData:rawData context:kCCEncrypt padding:kCCOptionECBMode|kCCOptionPKCS7Padding withKey:key];
}

+(NSData*)decrypt:(NSData*)ripeData withKey:(NSData*)key
{
    return [self dealData:ripeData context:kCCDecrypt padding:kCCOptionECBMode | kCCOptionPKCS7Padding withKey:key];
}



@end

