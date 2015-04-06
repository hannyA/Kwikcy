//
//  QPAsyncImageDownloader.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "KCAsyncMediaDownloader.h"

@protocol AsyncImageControllerProtocolDelegate <NSObject>
@required
- (void) setImageForReceivedMessage:(NSData *)data;
- (void) setImagesData:(NSData *)data forReceivedMessage:(ReceivedMessageImage *) message;
@optional
-(void)hideProgressHUD;

@end


@interface QPAsyncImageDownloader : KCAsyncMediaDownloader
@property (nonatomic, weak) id <AsyncImageControllerProtocolDelegate> asyncImageDelegate;
@end
