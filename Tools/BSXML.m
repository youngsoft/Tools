//
//  BSXML.m
//  Tools
//
//  Created by oybq on 14-1-10.
//  Copyright (c) 2014年 mobile. All rights reserved.
//

#import <libxml/parser.h>

#import "BSXML.h"


//获取某个兄弟节点下一个指定名字的兄弟节点
xmlNodePtr xmlNextElementSiblingByName(xmlNodePtr node, const xmlChar* name);
//获取某个节点下一个指定名字的子节点
xmlNodePtr xmlFirstElementChildByName(xmlNodePtr node, const xmlChar* name);
//获取某个子节点的千一个兄弟节点
xmlNodePtr xmlPreviousElementSiblingByName(xmlNodePtr node, const xmlChar* name);


//获取某个兄弟节点下一个指定名字的兄弟节点
xmlNodePtr xmlNextElementSiblingByName(xmlNodePtr node, const xmlChar* name)
{
	xmlNodePtr ret = NULL;
	if (node != NULL)
	{
		while ((node = xmlNextElementSibling(node)) != NULL)
		{
			if (xmlStrEqual(name, node->name) == 1)
			{
				ret = node;
				break;
			}
		}
	}
	
	return ret;
}

xmlNodePtr xmlPreviousElementSiblingByName(xmlNodePtr node, const xmlChar* name)
{
	xmlNodePtr ret = NULL;
	if (node != NULL)
	{
		while ((node = xmlPreviousElementSibling(node)) != NULL)
		{
			if (xmlStrEqual(name, node->name) == 1)
			{
				ret = node;
				break;
			}
		}
	}
	
	return ret;
}


xmlNodePtr xmlFirstElementChildByName(xmlNodePtr node, const xmlChar* name)
{
	if (node == NULL)
		return NULL;
	
	node = xmlFirstElementChild(node);
	if (node == NULL)
		return NULL;
	
	if (xmlStrEqual(name, node->name) == 1)
		return node;
	
	return xmlNextElementSiblingByName(node, name);
}



//内部实现
@interface BSXmlNode()

-(id)initWithNode:(xmlNodePtr)node;
+(id)nodeWithNode:(xmlNodePtr)node;

@end


@implementation BSXmlNode

void *_node;

-(id)initWithNode:(xmlNodePtr)node
{
	self = [super init];
	if (self != nil) {
		_node = node;
	}
	
	return self;
}

+(id)nodeWithNode:(xmlNodePtr)node
{
	return [[[BSXmlNode alloc] initWithNode:node] autorelease];
}

//获取名字
-(NSString*)name
{
	return [[[NSString alloc ] initWithUTF8String:(const char*)((xmlNodePtr)_node)->name] autorelease];
}

-(void)setName:(NSString*)name
{
    xmlNodeSetName(_node,  BAD_CAST [name UTF8String]);
}



//判断节点名字是否等于某个节点
-(BOOL) isEqualName:(NSString*)name
{
	return xmlStrEqual(((xmlNodePtr)_node)->name, BAD_CAST [name UTF8String]) == 1;
}

-(NSString*)attribute:(NSString*)name
{
    xmlChar *val = xmlGetProp(_node, BAD_CAST [name UTF8String]);
    if (val == NULL)
        return nil;
    
    NSString *ret = [NSString stringWithUTF8String:(const char*)val];
    xmlFree(val);
    return  ret;
}

-(BOOL)hasAttribute:(NSString*)name
{
    return xmlHasProp(_node, BAD_CAST [name UTF8String]) != NULL;
}

-(void)setAttribute:(NSString*)value name:(NSString*)name
{
    if (value == nil)
    {
        xmlAttrPtr attrPtr = xmlHasProp(_node, BAD_CAST [name UTF8String]);
        xmlRemoveProp(attrPtr);
    }
    else
        xmlSetProp(_node,BAD_CAST [name UTF8String],BAD_CAST [value UTF8String]);
}

//得到所有属性。
-(NSDictionary*)allAttributes
{
    NSMutableDictionary *allDict = [[NSMutableDictionary alloc] init];
    
    xmlNodePtr nodePtr = (xmlNodePtr)_node;
    
    xmlAttrPtr attr = nodePtr->properties;
    while (attr) {
        
        xmlChar *pcnt = xmlNodeGetContent(attr->children);
        [allDict setObject:[NSString stringWithUTF8String:(const char*)pcnt] forKey:[NSString stringWithUTF8String:(const char*)attr->name]];
        if (pcnt != NULL)
            xmlFree(pcnt);
        
        attr = attr->next;
    }
    
    
    return [allDict autorelease];
}



-(NSString*)stringValue
{
	xmlChar *pcnt = xmlNodeGetContent(_node);
	if (pcnt == NULL)
		return nil;
	
	NSString *ret = [[[NSString alloc ] initWithUTF8String:(const char *)pcnt] autorelease];
	xmlFree(pcnt);
	return ret;
}


-(int)intValue
{
	return self.stringValue.intValue;
}

-(long long)longLongValue
{
    return self.stringValue.longLongValue;
}

-(double)doubleValue
{
    return self.stringValue.doubleValue;
}

-(float)floatValue
{
    return self.stringValue.floatValue;
}

-(BOOL)boolValue
{
    return self.stringValue.boolValue;
}




-(NSString*)stringValue:(NSString*)subname
{
	xmlNodePtr pNode = xmlFirstElementChildByName(_node, BAD_CAST [subname UTF8String]);
	if (pNode == nil) {
		return nil;
	}
	
	xmlChar *pcnt = xmlNodeGetContent(pNode);
	if (pcnt == NULL)
		return nil;
	
	NSString *ret = [[[NSString alloc ] initWithUTF8String:(const char *)pcnt] autorelease];
	xmlFree(pcnt);
	return ret;
}

-(int)intValue:(NSString*)subname
{
    return [self stringValue:subname].intValue;
}

-(long long)longLongValue:(NSString*)subname
{
    return [self stringValue:subname].longLongValue;
}

-(double)doubleValue:(NSString*)subname
{
    return [self stringValue:subname].doubleValue;
}

- (float)floatValue:(NSString*)subname
{
    return [self stringValue:subname].floatValue;
}

- (BOOL)boolValue:(NSString*)subname
{
    return [self stringValue:subname].boolValue;
}


-(void)subNodeStringHelper:(BSXmlNode*)node result:(NSMutableString*)result includeSelf:(BOOL)includeSelf
{
    
    if (includeSelf)
    {
        [result appendFormat:@"<%@>",node.name];
    }
    
    BSXmlNode *firstNode = node.firstChild;
    if (firstNode == nil)
    {
        [result appendFormat:@"%@", [node stringValue]];
    }
    else
    {
        while (firstNode != nil)
        {
            [self subNodeStringHelper:firstNode result:result includeSelf:YES];
            firstNode = firstNode.nextSibling;
        }
    }
    
    if (includeSelf)
    {
        [result appendFormat:@"</%@>",node.name];
    }
}

-(NSString*)subNodeString:(BOOL)includeSelf;
{
    NSMutableString *result = [[NSMutableString alloc] init];
    
    [self subNodeStringHelper:self result:result includeSelf:includeSelf];
    
    return [result autorelease];
}

-(void)setStringValue:(NSString*)value
{
    xmlNodeSetContent(_node, BAD_CAST [value UTF8String]);
}

-(void)setStringValue:(NSString *)value subname:(NSString*)subname
{
    xmlNodePtr pNode = xmlFirstElementChildByName(_node, BAD_CAST [subname UTF8String]);
	if (pNode != nil)
    {
        xmlNodeSetContent(pNode, BAD_CAST [value UTF8String]);
	}
}


-(BSXmlNode*)addChild:(NSString*)name
{
	if (_node == NULL)
	{
		return nil;
	}
	
	xmlNodePtr pNode = xmlNewChild(_node, NULL, BAD_CAST [name UTF8String], NULL);
	if (pNode == NULL)
	{
		return nil;
	}
	
	return [BSXmlNode nodeWithNode:pNode];
}


-(void)addChild:(NSString*)name withString:(NSString*)value
{
	if (_node == NULL)
	{
		return;
	}
	
	xmlNodePtr pNode = xmlNewChild(_node, NULL, BAD_CAST [name UTF8String], BAD_CAST [value UTF8String]);
	if (pNode == NULL)
	{
		return;
	}
}

-(void)addChild:(NSString*)name withInt:(int)value
{
	[self addChild:name withString:[NSString stringWithFormat:@"%d", value]];
}

-(void)addChild:(NSString*)name withLongLong:(long long)value
{
	[self addChild:name withString:[NSString stringWithFormat:@"%lld", value]];
}

-(void)addChild:(NSString*)name withDouble:(double)value
{
	[self addChild:name withString:[NSString stringWithFormat:@"%f", value]];
}

-(void)addChild:(NSString*)name withFloat:(float)value
{
	[self addChild:name withString:[NSString stringWithFormat:@"%f", value]];
}



-(BSXmlNode*)firstChild
{
	xmlNodePtr pNode = xmlFirstElementChild(_node);
	if (pNode == NULL) {
		return nil;
	}
	
	return [BSXmlNode nodeWithNode:pNode];
}


-(BSXmlNode*)firstChild:(NSString*)name
{
	xmlNodePtr pNode = xmlFirstElementChildByName(_node, BAD_CAST [name UTF8String]);
	if (pNode == NULL) {
		return nil;
	}
	
	return [BSXmlNode nodeWithNode:pNode];
	
}

-(BSXmlNode*)nextSibling
{
	xmlNodePtr pNode = xmlNextElementSibling(_node);
	if (pNode == NULL) {
		return nil;
	}
	
	return [BSXmlNode nodeWithNode:pNode];
}

-(BSXmlNode*)nextSibling:(NSString*)name
{
	xmlNodePtr pNode = xmlNextElementSiblingByName(_node, BAD_CAST [name UTF8String]);
	if (pNode == NULL) {
		return nil;
	}
	
	
	return [BSXmlNode nodeWithNode:pNode];
}

-(BSXmlNode*)prevSibling
{
	xmlNodePtr pNode = xmlPreviousElementSibling(_node);
	if (pNode == NULL) {
		return nil;
	}
	
	return [BSXmlNode nodeWithNode:pNode];
}

-(BSXmlNode*)prevSibling:(NSString*)name
{
	xmlNodePtr pNode = xmlPreviousElementSiblingByName(_node, BAD_CAST [name UTF8String]);
	if (pNode == NULL) {
		return nil;
	}
	
	return [BSXmlNode nodeWithNode:pNode];
}




-(void)dealloc
{
	[super dealloc];
}

@end




//#define  BUMESSAGE_XMLENCODING  "UTF-8"


@implementation BSXmlDoc

void *_doc;

- (id) init
{
	self = [super init];
	if (self != nil) {
		_doc = xmlNewDoc(BAD_CAST "1.0");
		
	}
	return self;
}

-(id)initWithRoot:(NSString*)rootName
{
	self = [self init];
	if (self != nil)
	{
		xmlDocSetRootElement(_doc, xmlNewDocRawNode(_doc, NULL, BAD_CAST [rootName UTF8String], NULL));
	}
	
	return self;
}

- (id) initWithString:(NSString*)docString
{
	self = [super init];
	if (self != nil) {
		_doc = xmlParseDoc(BAD_CAST [docString UTF8String]);
	}
	return self;
}

-(id)initWithUTF8String:(const char*)docString
{
	self = [super init];
	if (self != nil) {
		_doc = xmlParseDoc(BAD_CAST docString);
	}
	return self;
}




+(id)xmlDocWithRoot:(NSString*)rootName
{
	return [[[BSXmlDoc alloc] initWithRoot:rootName] autorelease];
}

+(id)xmlDocWithString:(NSString*)docString
{
	return [[[BSXmlDoc alloc] initWithString:docString] autorelease];
}

+(id)xmlDocWithUTF8String:(const char*)docString
{
	return [[[BSXmlDoc alloc] initWithUTF8String:docString] autorelease];
}


-(BSXmlNode*) root
{
	xmlNodePtr pRoot = xmlDocGetRootElement(_doc);
	if (pRoot == NULL)
	{
		return nil;
	}
	
	return [[[BSXmlNode alloc] initWithNode:pRoot] autorelease];
}

//创建根节点
-(BSXmlNode *)setRoot:(NSString *)rootName
{
	xmlNodePtr pRoot = xmlDocGetRootElement(_doc);
	if (pRoot != NULL)
	{
		return nil;
	}
	
	pRoot = xmlNewDocRawNode(_doc, NULL, BAD_CAST [rootName UTF8String], NULL);
	if (pRoot == NULL)
	{
		return nil;
	}
	
	return [[[BSXmlNode alloc] initWithNode:pRoot] autorelease];
}


-(NSData*)dump
{
	xmlChar *pBuffer = NULL;
	int nBufferLen = 0;
	
    xmlDocDumpMemoryEnc(_doc, &pBuffer, &nBufferLen, "UTF-8");
    
    if (nBufferLen == 0)
    {
        xmlFree(pBuffer);
        return nil;
    }
    
    //去掉开始的空格和结束的空格
    // memmove(pBuffer + 21, pBuffer+22, nBufferLen - 22);
    
    xmlChar *pos = (xmlChar*)strchr((const char*)pBuffer, '>');
    if (pos != NULL)
    {
        int len = pos - pBuffer + 1;
        memmove(pBuffer + len, pBuffer+len + 1, nBufferLen - len - 1);
    }
    
    NSData *pData = [NSData dataWithBytes:pBuffer length:nBufferLen - 2];
    
    xmlFree(pBuffer);
    return  pData;
}

- (void) dealloc
{
	if (_doc != NULL) {
		xmlFreeDoc(_doc);
	}
	[super dealloc];
}



@end


