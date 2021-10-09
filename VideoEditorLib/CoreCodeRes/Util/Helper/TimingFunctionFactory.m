//
//  TimingFunctionFactory.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/22/21.
//

#import "TimingFunctionFactory.h"

@implementation TimingFunctionFactory

// Modeled after the quartic x^4
+(float)quarticEaseInWithP:(float)p {
    return p * p * p * p;
}

// Modeled after the quartic y = 1 - (x - 1)^4
+(float)quarticEaseOutWithP:(float)p {
    float f = (p - 1);
    return f * f * f * (1 - p) + 1;
}


// Modeled after the piecewise quadratic
// y = (1/2)((2x)^2)             ; [0, 0.5)
// y = -(1/2)((2x-1)*(2x-3) - 1) ; [0.5, 1]
+(float)quadraticEaseInOutWithP:(float)p {
    if(p < 0.5) {
        return 2 * p * p;
    } else {
        return (-2 * p * p) + (4 * p) - 1;
    }
}


@end
