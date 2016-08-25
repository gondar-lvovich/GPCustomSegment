//
//  GPCustomSegment.m
//  GPCustomSegment
//
//  Created by George Prokopchuk on 28.07.16.
//  Copyright © 2016 George Prokopchuk on. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPCustomSegment : UIControl


@property (nonatomic, assign) NSInteger selectedSegmentIndex;
@property (nonatomic, readonly) NSUInteger imagesCount;

- (instancetype)initWithImages:(NSArray *)images
            disabledImageColor:(UIColor *)disabledImageColor
            selectedImageColor:(UIColor *)selectedImageColor
             pressureViewColor:(UIColor *)pressureViewColor
               backgroundColor:(UIColor *)backgroundColor
                   borderColor:(UIColor *)borderColor
                      andFrame:(CGRect)frame;

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex animated:(BOOL)flag;

@end
