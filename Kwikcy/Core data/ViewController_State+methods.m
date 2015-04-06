//
//  ViewController_State+methods.m
//  Quickpeck
//
//  Created by Hanny Aly on 4/5/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "ViewController_State+methods.h"



#define MAX_TIME 60*10 // 10 minutes


@implementation ViewController_State (methods)


+(ViewController_State *)saveStateForViewController:(NSDictionary *)viewControllerState inManagedObjectContext:(NSManagedObjectContext *)context
{
    ViewController_State *newState = [NSEntityDescription insertNewObjectForEntityForName:CONTROLLER_STATE_TABLE inManagedObjectContext:context];

    
    newState.viewControllerName = viewControllerState[VIEWCONTROLLERNAME];
    newState.time               = viewControllerState[TIME];
    newState.valid              = viewControllerState[VALID];
    newState.action             = viewControllerState[ACTION];
    newState.objectView         = viewControllerState[OBJECTVIEW];
    newState.info               = viewControllerState[INFO];
    
    NSError *error = nil;
    
    if (![context save:&error]) {
        NSLog(@"Error saving state");
        // Handle the error.
        
        // Can't really do anything, can we? May not matter
        
    }
    NSLog(@"No error saving state with name %@", newState.viewControllerName);

    return newState;
}


+(ViewController_State *)getStateForViewController:(NSString *)viewController inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSLog(@"Viewcontroller name = %@", viewController);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:CONTROLLER_STATE_TABLE];
    request.sortDescriptors = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"viewControllerName = %@", viewController];
    
    // Execute the fetch
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches && [matches count] == 1)
    {
        NSLog(@"one match found for state");
        ViewController_State *state = [matches lastObject];
        
        CFTimeInterval startTime = [state.time doubleValue];
        CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
        
        NSLog(@"startTime = %f, elapsedTime = %f max time limit = %d", startTime,elapsedTime, MAX_TIME );

        if (elapsedTime > MAX_TIME)
        {
            NSLog(@"elapsedTime > MAX_TIME");

            [self deleteStateForViewController:state inManagedObjectContext:context];
            return nil;
        }
        
        
        return state;
        
        
    }
    else if (matches && [matches count] > 1)
    {
//        for (ViewController_State *foundState in matches)
//        {
//            NSArray *sortedArray;
//            sortedArray = [matches sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
//                NSNumber* first = ((ViewController_State*)a).time;
//                NSNumber* second = ((ViewController_State*)b).time;
//                return [first compare:second];
//            }];
//        }
        
        matches = [matches sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber* first = ((ViewController_State*)a).time;
            NSNumber* second = ((ViewController_State*)b).time;
            return [first compare:second];
        }];
        
        
        NSMutableArray *sortedArray = [matches mutableCopy];
        
        ViewController_State *lastState = [sortedArray lastObject];
        [sortedArray removeLastObject];
        
        for (ViewController_State *foundState in sortedArray)
        {
            [self deleteStateForViewController:foundState inManagedObjectContext:context];
        }
        
        
        
        CFTimeInterval startTime = [lastState.time doubleValue];
        CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
        
        NSLog(@"startTime = %f, elapsedTime = %f max time limit = %d", startTime, elapsedTime, MAX_TIME );
        
        if (elapsedTime > MAX_TIME)
        {
            NSLog(@"elapsedTime > MAX_TIME");
            
            [self deleteStateForViewController:lastState inManagedObjectContext:context];
            return nil;
        }
    }
    
    NSLog(@"matches count is %lu", [matches count]);
    
    NSLog(@"No matches found for state");

    return nil;
}



+(void)deleteStateForViewController:(ViewController_State *)state inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (state == nil)
        return;
    
    [context deleteObject:state];
    NSError *error = nil;
    
    if (![context save:&error]) {
        
        // Handle the error.
        
    }
}

@end

