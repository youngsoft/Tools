//
//  MyFtpUpload.h
//  MobileBC
//
//  Created by  on 12-10-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MyFtpUpload;

@protocol MyFtpUploadDelegate <NSObject>

@optional
-(void)MyFtpUpload:(MyFtpUpload*)ftpupload ok:(BOOL)ok;

@end

@interface MyFtpUpload : NSObject<NSStreamDelegate,MyFtpUploadDelegate>

@property(nonatomic, assign) id<MyFtpUploadDelegate> delegate;
@property(nonatomic, strong) NSString *hostURL;
@property(nonatomic, strong) NSString *remoteFile;
@property(nonatomic, strong) NSInputStream *inputStream;
@property(nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, strong) NSTimer *timeOut;
@property(nonatomic, assign) BOOL isOpen;
@property(nonatomic, assign) unsigned char *buffer;
@property(nonatomic, assign) int  remainRead;
@property(nonatomic, assign) int  hasWrite;

//如果localFile为nil则是建立一个文件夹, 如果是文件夹则remoteFile必需以/结尾。remoteFile必需以/开头。如果是文件夹则以/结束。
-(id)initWithURL:(NSString *)hostURL remoteFile:(NSString*)remoteFile localFile:(NSString*)localFile;

-(void)start;

-(void)stop;

@end
