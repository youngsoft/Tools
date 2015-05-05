//
//  MyFtpUpload.m
//  MobileBC
//
//  Created by  on 12-10-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MyFtpUpload.h"

@implementation MyFtpUpload

@synthesize delegate;
@synthesize hostURL;
@synthesize remoteFile;
@synthesize inputStream;
@synthesize outputStream;
@synthesize timeOut;
@synthesize isOpen;

@synthesize buffer;
@synthesize remainRead;
@synthesize hasWrite;

-(id)initWithURL:(NSString *)aHostURL remoteFile:(NSString*)aRemoteFile localFile:(NSString*)localFile
{
    self = [super init];
    if (self != nil)
    {
        self.delegate = nil;
        self.hostURL =  [aHostURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.remoteFile = aRemoteFile;
        if (localFile != nil)
            self.inputStream = [[NSInputStream alloc] initWithFileAtPath:localFile];
        self.isOpen = NO;
        self.remainRead = 0;
        self.hasWrite = 0;
        self.buffer = NULL;
    }
    
    return self;
    
}

-(void)handleTimeOut:(NSTimer*)timer
{
    if (!self.isOpen)
    {
        if (self.inputStream != nil)
            [self.inputStream close];
        self.inputStream = nil;
        
       
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(MyFtpUpload:ok:)])
        {
            [self.delegate MyFtpUpload:self ok:NO];
        }
        [self.outputStream close];
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [self release];
    }
    
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            
            NSLog(@"NSStreamEventOpenCompleted");
            self.isOpen = YES;
            if (self.timeOut != nil)
                [self.timeOut invalidate];
            self.timeOut = nil;
            
            //如果输入流是空的话这里应该是文件夹打开了。
            if (self.inputStream == nil)
            {
              
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(MyFtpUpload:ok:)])
                {
                    [self.delegate MyFtpUpload:self ok:YES];
                }
                
                [self.outputStream close];
                [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                
                [self release];
            }
            
        } break;
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"NSStreamEventHasBytesAvailable");

            
        } 
            break;
        case NSStreamEventHasSpaceAvailable: {
            
            //读流
            static  int TotalLen = 0;
             //unsigned char *buffer = malloc(64*1024);
            
            if (self.buffer == NULL)
            {
                self.buffer = malloc(64*1024);
                self.hasWrite = 0;
                self.remainRead = (int)[self.inputStream read:buffer maxLength:64*1024];
                TotalLen += self.remainRead;
            }
            
           
            if (self.remainRead > 0)
            {
                int write = (int)[self.outputStream write:buffer + self.hasWrite maxLength:self.remainRead];
                if (write == -1)
                {
                    if (self.inputStream != nil)
                        [self.inputStream close];
                    self.inputStream = nil;
             
                    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(MyFtpUpload:ok:)])
                    {
                        [self.delegate MyFtpUpload:self ok:NO];
                    }
                    [self.outputStream close];
                    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                    
                    
                    free(buffer);
                    buffer = NULL;
                    
                    [self release];

                }
                else
                {
                
                    self.hasWrite += write;
                    self.remainRead -= write;
                    
                    NSLog(@"total:%d, hasWrite:%d remainRead:%d",TotalLen, self.hasWrite, self.remainRead);
                    
                    if (self.remainRead == 0)
                    {
                        free(buffer);
                        buffer = NULL;
                        self.hasWrite = 0;
                    }
                }
            }
            else
            {
                if (self.inputStream != nil)
                    [self.inputStream close];
                self.inputStream = nil;
        
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(MyFtpUpload:ok:)])
                {
                    [self.delegate MyFtpUpload:self ok:YES];
                }
                [self.outputStream close];
                [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                
                free(buffer);
                buffer = NULL;

                
                [self release];
                
                

            }
            
                       
        } break;
        case NSStreamEventErrorOccurred: 
        {
            NSLog(@"NSStreamEventErrorOccurred");
            if (self.timeOut != nil)
                [self.timeOut invalidate];
            self.timeOut = nil;
            self.isOpen = YES;
            
            if (self.inputStream != nil)
                [self.inputStream close];
            self.inputStream = nil;
            
           
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(MyFtpUpload:ok:)])
            {
                [self.delegate MyFtpUpload:self ok:NO];
            }
            
            [self.outputStream close];
            [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            [self release];
            
        } break;
        case NSStreamEventEndEncountered: {
			NSLog(@"NSStreamEventEndEncountered");
            // ignore
        } break;
        default: {
        } break;
    }
	//NSLog(@"end of stream");
}

-(void)MyFtpUpload:(MyFtpUpload*)ftpupload ok:(BOOL)ok
{
    //如果成功了的话则打开。
    if (ok)
    {
        
        if (self.inputStream != nil)
            [self.inputStream open];
        
        NSString *fullPath = [[NSString stringWithFormat:@"%@%@", self.hostURL,self.remoteFile] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSURL *url = [NSURL URLWithString:fullPath];
        CFWriteStreamRef ftpStream = CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef) url);
        
        self.outputStream = (NSOutputStream *) ftpStream;
        
        self.outputStream.delegate = self;
        
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream open];
        if (ftpStream != nil)
            CFRelease(ftpStream);
        
        //定时器控制15秒后没有打开报错误。
        self.timeOut = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(handleTimeOut:) userInfo:nil repeats:NO];

    }
    else
    {
        //则应该继续传递失败。
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(MyFtpUpload:ok:)])
        {
            [self.delegate MyFtpUpload:self ok:NO];
        }
        
        [self release];
    }
    
    
}

 /*
    本方法采用递归的方法上传文件，因为文件夹如果没有则上传失败，所以这里要递归的进行文件夹的建立。
    ftpwritestream建立文件夹的方法是打开的时候末尾要带上/。表示建立的是文件夹。
    所以上传文件时递归打开上层的文件夹，直到上层的所有文件夹都建立为止。
  */
-(void)start
{
    [self retain];
    
    //去掉后面部分
   // NSLog(@"=====%@",self.remoteFile);
    NSString *dirPath = self.remoteFile.stringByDeletingLastPathComponent;
    // NSLog(@"=====%@",dirPath);
    if ([dirPath isEqualToString:@"/"])
    {
        
        if (self.inputStream != nil)
            [self.inputStream open];
        
        NSString *fullPath = [[NSString stringWithFormat:@"%@%@", self.hostURL,self.remoteFile] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        
        NSURL *url = [NSURL URLWithString:fullPath];
        CFWriteStreamRef ftpStream = CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef) url);
        
        self.outputStream = (NSOutputStream *) ftpStream;
        
        self.outputStream.delegate = self;
        
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream open];
        if (ftpStream != nil)
            CFRelease(ftpStream);
        
        //定时器控制15秒后没有打开报错误。
        self.timeOut = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(handleTimeOut:) userInfo:nil repeats:NO];
        
    }
    else
    {
        NSString *dirPath2 = [NSString stringWithFormat:@"%@/",dirPath];
        MyFtpUpload *myftp = [[MyFtpUpload alloc] initWithURL:self.hostURL remoteFile:dirPath2 localFile:nil];
        myftp.delegate = self;
        [myftp start];
        [myftp release];
    }
}

-(void)stop
{
    [self release];
}

-(void)dealloc
{
    if (timeOut != nil)
        [timeOut invalidate];
    [timeOut release];
       
    if (inputStream != nil)
        [inputStream close];
    [inputStream release];
    [hostURL release];
    [remoteFile release];
    
    if (outputStream  != nil)
    {
        outputStream.delegate = nil;
        [outputStream close];
    }
    [outputStream release];
    
        
    if (buffer != NULL)
        free(buffer);
    
    [super dealloc];

}


@end
