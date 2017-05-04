//
//  UIView+Frame.m
//  GeXingLive
//
//  Created by yuelixing on 16/6/17.
//  Copyright © 2016年 Tutu. All rights reserved.
//

#import "UIView+Frame.h"

@implementation UIView (Frame)

- (CGFloat)max_x{
    return self.frame.origin.x + self.frame.size.width;
}
- (CGFloat)max_y{
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setMax_x:(CGFloat)max_x {
    CGRect frame = self.frame;
    frame.origin.x = max_x-frame.size.width;
    self.frame = frame;
}
- (void)setMax_y:(CGFloat)max_y{
    CGRect frame = self.frame;
    frame.origin.y = max_y-frame.size.height;
    self.frame = frame;
}

- (void)setMj_centerX:(CGFloat)mj_centerX {
    CGPoint center = self.center;
    center.x = mj_centerX;
    self.center = center;
}

- (CGFloat)mj_centerX {
    return self.center.x;
}

- (void)setMj_centerY:(CGFloat)mj_centerY {
    CGPoint center = self.center;
    center.y = mj_centerY;
    self.center = center;
}

- (CGFloat)mj_centerY {
    return self.center.y;
}

@end
