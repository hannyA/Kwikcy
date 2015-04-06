//
//  KCProfileImageDownloader.h
//  Quickpeck
//
//  Created by Hanny Aly on 1/30/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "AsyncDownloader.h"


@protocol AsyncProfileImageControllerProtocolDelegate <NSObject>
@required
- (void) setImagesData:(NSData *)data;
@end


@interface KCProfileImageDownloader : AsyncDownloader
@property (nonatomic, weak) id <AsyncProfileImageControllerProtocolDelegate> asyncImageDelegate;
@end
