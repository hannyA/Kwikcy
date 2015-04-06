//
//  KCServerResponseHandler.h
//  Quickpeck
//
//  Created by Hanny Aly on 2/2/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "ResponseHandler.h"

@interface KCServerResponseHandler : ResponseHandler


@property (nonatomic, strong) NSString *decryptionKey;
@property (nonatomic, strong) NSString *command;

-(id)initWithKey:(NSString *)theDecryptionKey andComand:(NSString *)command;

-(Response *)handleResponse:(NSUInteger)responseCode body:(NSData *)responseBody;

@end
