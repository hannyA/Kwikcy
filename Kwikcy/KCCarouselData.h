//
//  KCCarouselData.h
//  Kwikcy
//
//  Created by Hanny Aly on 9/12/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCCarouselData : NSObject

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *dataInfo;


-(void)insertNewPhotos:(NSArray *)photos;
-(void)insertNewDataInfo:(NSArray *)dataInfo;

//-(void)transferDataInfo

@end
