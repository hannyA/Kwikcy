//
//  KCSynchronousUploader.h
//  Kwikcy
//
//  Created by Hanny Aly on 8/24/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSynchronousUploader : NSOperation
{
    BOOL           isExecuting;
    BOOL           isFinished;
}

@property (nonatomic, strong) NSDictionary   *messageDictionary;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) UIProgressView *progressView;


-(id)initWithMessageDictionary:(NSDictionary *)theMessageDictionary andProgressView:(UIProgressView *)progressView withManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext;

-(void)finish;
//-(void)initializeProgressView;
//-(void)updateProgressView:(NSNumber *)theProgress;
//-(void)hideProgressView;


@end
