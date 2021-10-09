//
//  TimingFunctionFactory.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/22/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimingFunctionFactory : NSObject

// Modeled after the quartic x^4
+(float)quarticEaseInWithP:(float)p;


// Modeled after the quartic y = 1 - (x - 1)^4
+(float)quarticEaseOutWithP:(float)p;


// Modeled after the piecewise quadratic
// y = (1/2)((2x)^2)             ; [0, 0.5)
// y = -(1/2)((2x-1)*(2x-3) - 1) ; [0.5, 1]
+(float)quadraticEaseInOutWithP:(float)p;


@end

NS_ASSUME_NONNULL_END
