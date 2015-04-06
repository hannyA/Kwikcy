//
//  ReceivedMessage.m
//  Quickpeck
//
//  Created by Hanny Aly on 1/26/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "ReceivedMessage.h"


@interface ReceivedMessage ()

@property (nonatomic, strong) Received_message *message;

@end

@implementation ReceivedMessage


-(Received_message *)getMessage
{
    return self.message;
}

-(NSString *)getMediaType
{
    return self.message.mediaType;
}

-(NSString *)getPersonFrom
{
    return self.message.from;
}


-(NSString *)getDate
{
    return self.message.date;
}


-(NSString *)getFilePath
{
    return self.message.filepath;
}



-(BOOL)hasBeenViewed
{
    return [self.message.view_status isEqualToString:@"YES"];
    //return ![self.message.view_status isEqualToString:@"NO"]; includes (YES, LOADING)
}

-(NSString *)getViewStatus
{
    return self.message.view_status;
}

-(void)setViewStatus:(NSString *)status
{
    self.message.view_status = status;
}



-(NSString *)getDateSender
{
   return self.message.date_sender;

}



-(BOOL)isEqualToMessage:(ReceivedMessage*)receivedMessage
{
    return [self.message.from isEqualToString:receivedMessage.message.from] &&
    [self.message.filepath isEqualToString:receivedMessage.message.filepath];
}



@end
