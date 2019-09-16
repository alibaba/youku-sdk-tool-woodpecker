//
//  YKWTouchIndicatorPlugin.m
//  YKWoodpecker
//
//  Created by Zim on 2019/4/21.
//  Copyright © 2019 Youku. All rights reserved.
//
//  MIT License
//
//  Copyright (c) 2019 Alibaba
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "YKWTouchIndicatorPlugin.h"
#import "NSObject+YKWoodpeckerRuntime.h"

@implementation YKWTouchIndicatorPlugin

- (void)runWithParameters:(NSDictionary *)paraDic {
    if (![[UIApplication sharedApplication] respondsToSelector:@selector(ykwoodpeckerSendEvent:)]) {
        ykwoodpeckerRuntimeAddMethod([UIApplication class], @selector(ykwoodpeckerSendEvent:), [YKWTouchIndicatorPlugin class], @selector(ykwoodpeckerSendEvent:));
    }
    [UIApplication ykwoodpeckerRuntimeSwizzleSelector:@selector(sendEvent:) withSelector: @selector(ykwoodpeckerSendEvent:)];
}

- (void)ykwoodpeckerSendEvent:(UIEvent *)event {
    [self ykwoodpeckerSendEvent:event];

    if (event.type == UIEventTypeTouches) {
        for (UITouch *touch in [event.allTouches allObjects]) {
            if (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary) {
                CALayer *layer = [CALayer layer];
                layer.frame = CGRectMake(0, 0, 20, 20);
                layer.anchorPoint = CGPointMake(0.5, 0.5);
                layer.position = [touch locationInView:touch.window];
                layer.masksToBounds = YES;
                layer.cornerRadius = layer.bounds.size.width / 2.0;
                float r = 0, g = 0, b = 0;
                ykw_HSLtoRGB((arc4random() % 360), 1.0, 0.75, &r, &g, &b);
                layer.backgroundColor = [UIColor colorWithRed:r/255. green:g/255. blue:b/255. alpha:1].CGColor;
                [touch.window.layer addSublayer:layer];
                // Animations
                CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
                opacityAnimation.toValue = [NSNumber numberWithFloat:0.0];
                opacityAnimation.duration = 0.5;
                opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                opacityAnimation.fillMode = kCAFillModeBoth;
                opacityAnimation.removedOnCompletion = NO;
                
                CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
                scaleAnimation.fromValue = [NSNumber numberWithFloat:1.0];
                scaleAnimation.toValue = [NSNumber numberWithFloat:3.0];
                scaleAnimation.duration = 0.5;
                scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                scaleAnimation.fillMode = kCAFillModeBoth;
                scaleAnimation.removedOnCompletion = NO;
                
                [layer addAnimation:opacityAnimation forKey:@"opacity"];
                [layer addAnimation:scaleAnimation forKey:@"scale"];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [layer removeFromSuperlayer];
                });
            }
        }
    }
}

void ykw_HSLtoRGB (float h, float s, float l, float* R, float* G, float* B) {
    float v1, v2;
    float H = h/360.0;
    float S = s;
    float L = l;
    if (0 == S) {
        *R = L * 255;
        *G = L * 255;
        *B = L * 255;
    } else {
        if (L < 0.5)
            v2 = L * (1+S);
        else
            v2 = (L+S) - (L*S);
        
        v1 = 2 * L - v2;
        *R = 255 * ykw_HuetoRGB(v1, v2, H+(1.0/3.0));
        *G = 255 * ykw_HuetoRGB(v1, v2, H);
        *B = 255 * ykw_HuetoRGB(v1, v2, H-(1.0/3.0));
    }
}

float ykw_HuetoRGB (float v1, float v2, float vH) {
    if (vH < 0)
        vH += 1;
    if (vH > 1)
        vH -= 1;
    if ((6*vH) < 1)
        return (v1 + (v2-v1)*6*vH);
    if ((2*vH) < 1)
        return v2;
    if ((3*vH) < 2)
        return (v1 + (v2-v1)*((2.0/3.0)-vH)*6);
    return v1;
}

@end
