//
//  BSXML.h
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * XML节点
 */
@interface BSXmlNode : NSObject

@property(nonatomic, retain) NSString * name;


//判断节点名字是否等于某个节点
-(BOOL) isEqualName:(NSString*)name;

//获取属性，如果没有属性则返回nil
-(NSString*)attribute:(NSString*)name;

//判断某个属性是否存在
-(BOOL)hasAttribute:(NSString*)name;

//如果没有name那么就增加属性, 如果value为nil那么表示删除。
-(void)setAttribute:(NSString*)value name:(NSString*)name;

//得到所有属性。
-(NSDictionary*)allAttributes;


//获取节点的内容
- (NSString*)stringValue;
- (int)intValue;
- (long long)longLongValue;
- (double)doubleValue;
- (float)floatValue;
- (BOOL)boolValue;

-(NSString*)stringValue:(NSString*)subname;
-(int)intValue:(NSString*)subname;
-(long long)longLongValue:(NSString*)subname;
-(double)doubleValue:(NSString*)subname;
-(float)floatValue:(NSString*)subname;
-(BOOL)boolValue:(NSString*)subname;

//得到子节点构造出来XML格式的字符串。includeSelf指明是否包括自己
-(NSString*)subNodeString:(BOOL)includeSelf;


-(void)setStringValue:(NSString*)value;
-(void)setStringValue:(NSString *)value subname:(NSString*)subname;

//建立某个子节点，前者有返回，后者不返回,后者直接带上内容 主要用于前者建立有子节点的节点，而后者一般建立叶子节点
-(BSXmlNode*)addChild:(NSString*)name;

-(void)addChild:(NSString*)name withString:(NSString*)value;
-(void)addChild:(NSString*)name withInt:(int)value;
-(void)addChild:(NSString*)name withLongLong:(long long)value;
-(void)addChild:(NSString*)name withDouble:(double)value;
-(void)addChild:(NSString*)name withFloat:(float)value;


//获取第一个子节点或者某个命名的子节点
-(BSXmlNode*)firstChild;
-(BSXmlNode*)firstChild:(NSString*)name;
-(BSXmlNode*)nextSibling;
-(BSXmlNode*)nextSibling:(NSString*)name;
-(BSXmlNode*)prevSibling;
-(BSXmlNode*)prevSibling:(NSString*)name;

@end

/*
 *xml文档类
 */
@interface BSXmlDoc : NSObject

-(id)initWithRoot:(NSString*)rootName;
-(id)initWithString:(NSString*)docString;
-(id)initWithUTF8String:(const char*)docString;

+(id)xmlDocWithRoot:(NSString*)rootName;
+(id)xmlDocWithString:(NSString*)docString;
+(id)xmlDocWithUTF8String:(const char*)docString;

//获取根节点
-(BSXmlNode*)root;
//创建根节点,主要是调用init后调用下面函数
-(BSXmlNode*)setRoot:(NSString*)rootName;

//将文档序列化为字符串
-(NSData*)dump;

@end

