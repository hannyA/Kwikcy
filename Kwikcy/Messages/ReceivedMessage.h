//
//  ReceivedMessage.h
//  Quickpeck
//
//  Created by Hanny Aly on 1/26/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

/*
 * ABSTRACT CLASS
 */

#import <Foundation/Foundation.h>
#import "Received_message+methods.h"



@interface ReceivedMessage : NSObject


-(Received_message *)getMessage;

-(NSString *)getMediaType;
-(NSString *)getPersonFrom;
-(NSString *)getDate;

-(NSString *)getFilePath;

-(void)setViewStatus:(NSString *)status;
-(NSString *)getViewStatus;
-(BOOL)hasBeenViewed;


-(NSString *)getDateSender;

-(BOOL)isEqualToMessage:(ReceivedMessage*)receivedMessage;



@end
