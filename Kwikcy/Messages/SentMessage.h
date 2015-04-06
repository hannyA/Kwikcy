//
//  SentMessage.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/23/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sent_message+methods.h"

@interface SentMessage : NSObject

-(id)initWithSentMessage:(Sent_message *)message;


-(Sent_message *)getSentMessage;


-(NSString *)getDate;
-(NSString *)getFilePath;

-(NSString *)getMediaType;
-(NSString *)getMessage;
-(NSString *)getReceivers;
-(NSString *)getSender;
-(NSString *)getStatus;

-(NSString *)getUnsendKey;


-(BOOL)didAddSelfToNotification;


-(NSString *)getUpdatedStatus:(NSManagedObjectContext *)context;

//
//-(void)setViewStatus:(NSString *)status;
//-(NSString *)getViewStatus;
//-(BOOL)hasBeenViewed;
//
//
//-(NSString *)getDateSender;


@end
