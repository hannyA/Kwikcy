//
//  QPTouchCell.h
//  Quickpeck
//
//  Created by Hanny Aly on 12/31/13.
//  Copyright (c) 2013 Hanny Aly. All rights reserved.
//

//TODO: DELETE:

#import <UIKit/UIKit.h>


@protocol QPTableViewProtocolDelegate <NSObject>
@required
-(void)thisTableViewCellIsHeldDownWithIndexpath:(NSIndexPath *)indexPath;
-(void)thisTableViewCellIsReleasedWithIndexpath:(NSIndexPath *)indexPath;

// Used for Screenshot
-(void)thisTableViewCellIsCanceledWithIndexpath:(NSIndexPath *)indexPath;

@optional
-(void)thisTableViewCellIsMovedWithIndexpath:(NSIndexPath *)indexPath;
@end



@interface QPTableViewTouchCell : UITableViewCell
    // Delegate to respond back
@property (nonatomic,strong) id <QPTableViewProtocolDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath; //Holds the indexPath of the cell

@end