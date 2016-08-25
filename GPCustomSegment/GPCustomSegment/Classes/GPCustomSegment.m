//
//  GPCustomSegment.m
//  GPCustomSegment
//
//  Created by George Prokopchuk on 28.07.16.
//  Copyright © 2016 George Prokopchuk on. All rights reserved.
//

#import "GPCustomSegment.h"

static const CGFloat kCustomSegmentHeightMultiplier = 0.8f;
static const CGFloat kCustomSegmentWidthMultiplier = 2.0f;
static const NSTimeInterval kAnimationDuration = 0.4f;

@interface GPCustomSegment ()
{
    CGSize standardSize;
    UIColor * _selectedImageColor;
    UIColor * _backgroundSegmentColor;
    UIColor * _borderColor;
    UIColor * _pressureViewColor;
    UIColor * _disabledImageColor;
}

@property (nonatomic, copy) NSMutableDictionary *titleTextAttributes;
@property (nonatomic, copy) NSMutableArray *segmentImages;
@property (nonatomic, copy) NSMutableArray *selectedImageViews;
@property (nonatomic, copy) NSMutableArray *imageViews;
@property (nonatomic, strong) UIView *pressureView;
@property (nonatomic, strong) UIView *selectedImageViewContainer;
@property (nonatomic, strong) UIView *imageViewContainer;
@property (nonatomic, strong) UIView *pressureViewShowLayer;
@property (nonatomic, strong) CALayer *maskLayer;

@end

@implementation GPCustomSegment


- (instancetype)initWithImages:(NSArray *)images
            disabledImageColor:(UIColor *)disabledImageColor
            selectedImageColor:(UIColor *)selectedImageColor
             pressureViewColor:(UIColor *)pressureViewColor
               backgroundColor:(UIColor *)backgroundColor
                   borderColor:(UIColor *)borderColor
                      andFrame:(CGRect)frame
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    _disabledImageColor = disabledImageColor;
    _pressureViewColor = pressureViewColor;
    _selectedImageColor = selectedImageColor;
    _backgroundSegmentColor = backgroundColor;
    _borderColor = borderColor;
    _segmentImages = [images mutableCopy];
    _titleTextAttributes = [NSMutableDictionary dictionary];
    if (_segmentImages.count > 0)
    {
        [self findStandardSizeFromImage:_segmentImages.firstObject];
    }
    [self initElements];
    [self setupImagesArray:images];
    self.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    return self;
}

- (void)findStandardSizeFromImage:(NSString *)imageString
{
    UIImage *image = [UIImage imageNamed:imageString];
    standardSize = image.size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutImageViews];
    [self layoutPressureView];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self drawBackground];
    for (UIImageView *imageView in self.selectedImageViews)
    {
        imageView.tintColor = _selectedImageColor;
    }
}

- (NSUInteger)imagesCount
{
    return self.segmentImages.count;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    [self setSelectedSegmentIndex:selectedSegmentIndex animated:YES];
}

- (void)setPressureViewColor:(UIColor *)selectionViewColor
{
    self.pressureView.backgroundColor = selectionViewColor;
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    [self setNeedsDisplay];
}

-(void)setDisabledImageColor:(UIColor *)disabledImageColor
{
    _disabledImageColor = disabledImageColor;
    [_selectedImageViews removeAllObjects];
    [_imageViews removeAllObjects];
    [self setupImagesArray:_segmentImages];
    [self setNeedsDisplay];
}

- (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    CGFloat width = newSize.width * kCustomSegmentWidthMultiplier;
    CGFloat height = newSize.width;
    // for same format
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGPoint origin = CGPointMake((width - img.size.width) / 2.0f,(height - img.size.height) / 2.0f);
    [img drawAtPoint:origin];
    UIGraphicsPopContext();
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex animated:(BOOL)flag
{
    _selectedSegmentIndex = selectedSegmentIndex;
    [self movePressureViewToSelectedSegment:selectedSegmentIndex animated:flag];
}


- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super beginTrackingWithTouch:touch withEvent:event];
    
    CGPoint touchPoint = [touch locationInView:self];
    BOOL shouldBeginTouches = [self isValidTouchPoint:touchPoint];
    
    return shouldBeginTouches;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super continueTrackingWithTouch:touch withEvent:event];
    
    CGFloat horizontalDifference = [touch locationInView:self].x - [touch previousLocationInView:self].x;
    CGRect newFrame = self.pressureView.frame;
    newFrame.origin.x += horizontalDifference;
    
    if (![self isPressureViewFrameValid:newFrame])
    {
        newFrame = [self validatedPressureViewFrame:newFrame];
    }
    
    [self movePressureViewToFrame:newFrame];
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    
    
    NSInteger nearestIndex = [self nearestIndexForCurrentThumbPosition];
    
    if (nearestIndex != self.selectedSegmentIndex)
    {
        [self updateSelectedIndexAndNotify:nearestIndex];
    }
    else
    {
        [self movePressureViewToSelectedSegment:self.selectedSegmentIndex animated:YES];
    }
    
}


- (void)initElements
{
    self.backgroundColor = [UIColor clearColor];
    _selectedSegmentIndex = 0;
    _selectedImageViews = [NSMutableArray array];
    _imageViews = [NSMutableArray array];
    
    [self setupPressureView];
    [self setupImageViewContainers];
    [self setupMaskLayer];
    [self setupPressureViewShowLayer];
    
    [self addSubview:self.pressureView];
    [self addSubview:self.imageViewContainer];
    [self addSubview:self.selectedImageViewContainer];
    
    self.selectedImageViewContainer.layer.mask = self.maskLayer;
    [self.maskLayer addSublayer:self.pressureViewShowLayer.layer];
}

- (void)setupPressureView
{
    self.pressureView = [UIView new];
    self.pressureView.backgroundColor = _pressureViewColor;
    self.pressureView.userInteractionEnabled = NO;
}

- (void)setupImageViewContainers
{
    self.selectedImageViewContainer = [UIView new];
    self.selectedImageViewContainer.userInteractionEnabled = NO;
    self.imageViewContainer = [UIView new];
    self.imageViewContainer.userInteractionEnabled = NO;
}

- (void)setupMaskLayer
{
    self.maskLayer = [CALayer layer];
    self.maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
}

- (void)setupPressureViewShowLayer
{
    self.pressureViewShowLayer = [UIView new];
    self.pressureViewShowLayer.backgroundColor = [UIColor whiteColor];
}

- (void)layoutMasks
{
    self.maskLayer.frame = self.selectedImageViewContainer.bounds;
    self.pressureViewShowLayer.bounds = [self pressureRect];
    self.pressureViewShowLayer.center = [self centerForSegmentAtIndex:self.selectedSegmentIndex];
    self.pressureViewShowLayer.layer.cornerRadius = CGRectGetHeight([self pressureRect]) / 2.0f;
}

- (void)setupImagesArray:(NSArray *)images
{
    for (NSInteger i = 0; i < images.count; i++)
    {
        UIImage *image = [UIImage imageNamed:images[i]];
        image = [self imageResize:image andResizeTo:standardSize];
        [self addImage:image atIndex:i];
    }
}


- (void)layoutImageViews
{
    self.selectedImageViewContainer.frame = self.bounds;
    self.imageViewContainer.frame = self.bounds;
    
    CGFloat segmentWidth = CGRectGetWidth(self.bounds) / [self imagesCount];
    
    for (NSUInteger index = 0; index < self.selectedImageViews.count; index++) {
        UIImageView *foreground = self.selectedImageViews[index];
        UIImageView *background = self.imageViews[index];
        
        CGRect desiredRect = [self rectForImageViewAtIndex:index withSegmentWidth:segmentWidth boundingRect:self.bounds];
        foreground.frame = desiredRect;
        background.frame = desiredRect;
    }
    
    [self layoutMasks];
}

- (void)layoutPressureView
{
    self.pressureView.bounds = [self pressureRect];
    self.pressureView.center = [self centerForSegmentAtIndex:self.selectedSegmentIndex];
    self.pressureView.layer.cornerRadius = CGRectGetHeight([self pressureRect]) / 2.0f;
}

- (CGRect)rectForImageViewAtIndex:(NSUInteger)index withSegmentWidth:(CGFloat)segmentWidth boundingRect:(CGRect)boundingRect
{
    CGFloat width = segmentWidth;
    CGFloat height = CGRectGetHeight(boundingRect) * kCustomSegmentHeightMultiplier; // change size of image
    CGFloat x = (segmentWidth * index);
    CGFloat y = CGRectGetHeight(boundingRect) / 2 - height / 2;
    return CGRectMake(x, y, width, height);
}

- (void)drawBackground
{
    UIBezierPath *backgroundPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:CGRectGetHeight(self.bounds) / 2.0f];
    [_backgroundSegmentColor setFill];
    [backgroundPath fill];
    UIView *viewBackBorders = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width ,self.frame.size.height )];
    viewBackBorders.layer.cornerRadius = CGRectGetHeight([self frame]) / 2.0f;
    viewBackBorders.layer.borderColor = _borderColor.CGColor;
    viewBackBorders.layer.borderWidth = 1.0f;
    viewBackBorders.layer.masksToBounds = YES;
    [self addSubview:viewBackBorders];
    viewBackBorders.layer.zPosition = -90;
    viewBackBorders.userInteractionEnabled = NO;
    
}

- (BOOL)isValidTouchPoint:(CGPoint)touchPoint
{
    BOOL touchedSelectedSegment = CGRectContainsPoint([self rectForSelectedSegment], touchPoint);
    BOOL touchedOtherSegment = NO;
    NSInteger selectedIndex = 0;
    for (NSInteger idx = 0; idx < self.segmentImages.count; idx++) {
        if (CGRectContainsPoint([self rectForSegmentAtIndex:idx], touchPoint) &&
            idx != self.selectedSegmentIndex) {
            touchedOtherSegment = YES;
            selectedIndex = idx;
            [self updateSelectedIndexAndNotify:idx];
            break;
        }
    }
    BOOL shouldBeginTouches = NO;
    
    if (touchedSelectedSegment || touchedOtherSegment) {
        shouldBeginTouches = YES;
    }
    return shouldBeginTouches;
}

- (BOOL)isPressureViewFrameValid:(CGRect)newRect {
    return CGRectContainsRect(self.bounds, newRect);
}

- (CGRect)validatedPressureViewFrame:(CGRect)newFrame {
    CGRect validatedFrame = newFrame;
    if (CGRectGetMaxX(newFrame) > CGRectGetMaxX(self.bounds))
    {
        CGFloat maxDifference = CGRectGetMaxX(newFrame) - CGRectGetMaxX(self.bounds);
        validatedFrame.origin.x -= maxDifference;
    }
    else if (CGRectGetMinX(newFrame) < CGRectGetMinX(self.bounds))
    {
        CGFloat minDifference = CGRectGetMinX(self.bounds) - CGRectGetMinX(newFrame);
        validatedFrame.origin.x += minDifference;
    }
    
    return validatedFrame;
}

- (NSInteger)nearestIndexForCurrentThumbPosition
{
    NSInteger nearestIndex = 0;
    CGFloat smallestDifference = CGFLOAT_MAX;
    for (NSInteger i = 0; i < self.segmentImages.count; i++)
    {
        CGRect segmentRect = [self rectForSegmentAtIndex:i];
        CGPoint segmentCenter = CGPointMake(CGRectGetMidX(segmentRect), CGRectGetMidY(segmentRect));
        CGFloat difference = ABS(self.pressureView.center.x - segmentCenter.x);
        if (difference < smallestDifference)
        {
            smallestDifference = difference;
            nearestIndex = i;
        }
    }
    return nearestIndex;
}

- (void)updateSelectedIndexAndNotify:(NSInteger)newIndex
{
    self.selectedSegmentIndex = newIndex;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)movePressureViewToFrame:(CGRect)newThumbFrame
{
    self.pressureView.frame = newThumbFrame;
    self.pressureViewShowLayer.frame = newThumbFrame;
}

- (void)addImage:(UIImage *)image atIndex:(NSUInteger)index
{
    UIImageView *foreground = [self viewWithImage:image tintColor:_selectedImageColor];
    UIImageView *background = [self viewWithImage:image tintColor:_disabledImageColor];
    [self.selectedImageViews insertObject:foreground atIndex:index];
    [self.imageViews insertObject:background atIndex:index];
    [self.selectedImageViewContainer addSubview:foreground];
    [self.imageViewContainer addSubview:background];
}

- (UIImageView *)viewWithImage:(UIImage *)image tintColor:(UIColor *)textColor
{
    UIImageView *imageView = [UIImageView new];
    [imageView setImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [imageView setTintColor:textColor];
    return imageView;
}

- (CGRect)pressureRect
{
    CGFloat width;
    if ([self imagesCount] > 0)
    {
        width = CGRectGetWidth(self.bounds) / [self imagesCount] - 2;
    }
    else
    {
        width = CGRectGetWidth(self.bounds) - 2;
    }
    
    CGFloat height = self.frame.size.height - 2;
    
    return CGRectMake(self.bounds.origin.x, self.bounds.origin.y, width,height);
}

- (void)movePressureViewToSelectedSegment:(NSInteger)index animated:(BOOL)animated
{
    
    CGRect newSelectionRect = [self rectForSegmentAtIndex:index];
    CGPoint newCenter = [self centerForSegmentAtIndex:index];
    if (animated)
    {
        if (![self.pressureView.layer animationForKey:@"basic"])
        {
            CABasicAnimation *basicAnimation = [self pressureViewAnimationWithFromCenter:self.pressureView.center toCenter:newCenter];
            [self.pressureView.layer addAnimation:basicAnimation forKey:@"basic"];
            self.pressureView.layer.position = newCenter;
            
            CABasicAnimation *positionAnimation = [self pressureViewAnimationWithFromCenter:self.pressureViewShowLayer.center toCenter:newCenter];
            [self.pressureViewShowLayer.layer addAnimation:positionAnimation forKey:@"position"];
            self.pressureViewShowLayer.layer.position = newCenter;
        }
    }
    else
    {
        [self movePressureViewToFrame:newSelectionRect];
    }
}

- (CABasicAnimation *)pressureViewAnimationWithFromCenter:(CGPoint)fromCenter toCenter:(CGPoint)toCenter
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.fromValue = [NSValue valueWithCGPoint:fromCenter];
    animation.toValue = [NSValue valueWithCGPoint:toCenter];
    animation.duration = kAnimationDuration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.delegate = self;
    return animation;
}

- (CGRect)rectForSelectedSegment
{
    return [self rectForSegmentAtIndex:self.selectedSegmentIndex];
}

- (CGRect)rectForSegmentAtIndex:(NSInteger)index
{
    if (index < [self imagesCount]) {
        UIImageView *segment = self.selectedImageViews[index];
        return segment.frame;
    } else {
        return CGRectZero;
    }
}

- (CGPoint)centerForSegmentAtIndex:(NSUInteger)index
{
    if (index < [self imagesCount])
    {
        UIImageView *segment = self.selectedImageViews[index];
        return segment.center;
    }
    else
    {
        return CGPointZero;
    }
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self.pressureView.layer removeAllAnimations];
    [self.pressureViewShowLayer.layer removeAllAnimations];
}

@end
