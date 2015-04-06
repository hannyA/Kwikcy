//
//  SentMessage.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/23/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "SentMessage.h"

@interface SentMessage ()
@property (nonatomic, strong) Sent_message *message;
@property (nonatomic) BOOL addedToNotificaiton;
@end


@implementation SentMessage

-(id)initWithSentMessage:(Sent_message *)message
{
    self = [super init];
    if (self)
    {
        self.message = message;
    }
    return self;
}

-(Sent_message *)getSentMessage
{
    return self.message;
}

-(BOOL)didAddSelfToNotification
{
    if (!self.addedToNotificaiton)
    {
        self.addedToNotificaiton = YES;
        return NO;
    }
    return self.addedToNotificaiton;
}

-(NSString *)getDate
{
    return self.message.date;
}

-(NSString *)getFilePath
{
    return self.message.filepath;
}

-(NSString *)getMediaType
{
    return self.message.mediaType;
}
-(NSString *)getMessage
{
    return self.message.message;
}

-(NSString *)getReceivers
{
    return self.message.receivers;
}

-(NSString *)getSender
{
    return self.message.sender;

}

-(NSString *)getStatus
{
    return self.message.status;
}

-(NSString *)getUnsendKey
{
    return self.message.unsend_key;
}




-(NSString *)getUpdatedStatus:(NSManagedObjectContext *)context
{
    return [Sent_message getStatusOfMessage:self.message inManagedObjectContext:context];
}



@end
