//
//  Search.h
//  StoreSearch
//
//  Created by Ajay Singh on 2/6/15.
//  Copyright (c) 2015 Ajay Singh. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^SearchBlock)(BOOL success);


@interface Search : NSObject

@property (nonatomic, assign) BOOL isLoading;

@property (nonatomic, readonly, strong) NSMutableArray *searchResults;

-(void)performSearchForText:(NSString *)text
                   category:(NSInteger)category
                   completion:(SearchBlock)block;

@end