//
//  QPAsyncVideoDownloader.h
//  Quickpeck
//
//  Created by Hanny Aly on 7/20/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

#import "KCAsyncMediaDownloader.h"


@protocol AsyncVideoControllerProtocolDelegate <NSObject>
@required
- (void) setVideoForReceivedMessage:(NSString*)path;
@end

@interface QPAsyncVideoDownloader : KCAsyncMediaDownloader
@property (nonatomic, weak) id <AsyncVideoControllerProtocolDelegate> asyncVideoDelegate;

@end
