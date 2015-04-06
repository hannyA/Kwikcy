//
//  KCServerRequest.h
//  Quickpeck
//
//  Created by Hanny Aly on 1/31/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Request.h"
#import "Response.h"
#import "ResponseHandler.h"

@interface KCServerRequest : Request


@property (nonatomic, strong) NSString *command;
@property (nonatomic, strong) NSString *decryptionKey;
@property (nonatomic, strong) NSData   *finalBody;


-(NSString *)getUrl;


-(id)initWithParameters:(NSMutableDictionary *)parameters;

@end
