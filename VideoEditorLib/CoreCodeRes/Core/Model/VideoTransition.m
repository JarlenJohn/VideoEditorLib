//
//  VideoTransition.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/8/21.
//

#import "VideoTransition.h"
#import "TimingFunctionFactory.h"
#import "CIImage+Helper.h"
#import <UIKit/UIKit.h>

@interface NoneTransition ()

@property(nonatomic, assign) CMTime duration;
@end


@implementation NoneTransition

@synthesize identifier = _identifier;
@synthesize duration = _duration;

- (instancetype)initWithDuration:(CMTime)duration {
    if (self = [super init]) {
        self.duration = duration;
    }
    return self;
}

- (NSString *)identifier {
    return NSStringFromClass([self class]);
}

- (CIImage *)renderImageWithForegroundImage:(CIImage *)foregroundImage
                            backgroundImage:(CIImage *)backgroundImage
                             forTweenFactor:(CGFloat)tween
                                 renderSize:(CGSize)renderSize {
    return foregroundImage;
}


@end


@implementation CrossDissolveTransition
- (CIImage *)renderImageWithForegroundImage:(CIImage *)foregroundImage backgroundImage:(CIImage *)backgroundImage forTweenFactor:(CGFloat)tween renderSize:(CGSize)renderSize {
    CIFilter *crossDissolveFilter = [CIFilter filterWithName:@"CIDissolveTransition"];
    if (crossDissolveFilter) {
        [crossDissolveFilter setValue:backgroundImage forKey:@"inputImage"];
        [crossDissolveFilter setValue:foregroundImage forKey:@"inputTargetImage"];
        [crossDissolveFilter setValue:@(tween) forKey:@"inputTime"];
        
        CIImage *outputImage = crossDissolveFilter.outputImage;
        if (outputImage) {
            return outputImage;
        }
    }
    
    return [super renderImageWithForegroundImage:foregroundImage
                                 backgroundImage:backgroundImage
                                  forTweenFactor:tween
                                      renderSize:renderSize];
}

@end


@implementation SwipeTransition

- (CIImage *)renderImageWithForegroundImage:(CIImage *)foregroundImage backgroundImage:(CIImage *)backgroundImage forTweenFactor:(CGFloat)tween renderSize:(CGSize)renderSize {
    CIFilter *filter = [CIFilter filterWithName:@"CISwipeTransition"];
    if (filter) {
        CIImage *targetImage = foregroundImage;
        [filter setValue:backgroundImage forKey:@"inputImage"];
        [filter setValue:targetImage forKey:@"inputTargetImage"];
        [filter setValue:@(tween) forKey:@"inputTime"];
        CIVector *extent = [CIVector vectorWithX:targetImage.extent.origin.x
                                              Y:targetImage.extent.origin.y
                                              Z:targetImage.extent.size.width
                                              W:targetImage.extent.size.height];
        [filter setValue:extent forKey:@"inputExtent"];
        [filter setValue:@(targetImage.extent.size.width) forKey:@"inputWidth"];
        
        CIImage *outputImage = filter.outputImage;
        if (outputImage) {
            return outputImage;
        }
    }
    return [super renderImageWithForegroundImage:foregroundImage
                                 backgroundImage:backgroundImage
                                  forTweenFactor:tween
                                      renderSize:renderSize];
}
@end


@implementation PushTransition

- (CIImage *)renderImageWithForegroundImage:(CIImage *)foregroundImage backgroundImage:(CIImage *)backgroundImage forTweenFactor:(CGFloat)tween renderSize:(CGSize)renderSize {
    
    tween = [TimingFunctionFactory quadraticEaseInOutWithP:tween];
    CGAffineTransform offsetTransform = CGAffineTransformMakeTranslation(renderSize.width*tween, 0);
    CIImage *bgImage = [self image:backgroundImage applyWithTransfrom:offsetTransform];
    
    CGAffineTransform foregroundTransform = CGAffineTransformMakeTranslation(renderSize.width * (-1 + tween), 0);
    CIImage *frontImage = [self image:foregroundImage applyWithTransfrom:foregroundTransform];
    
    CIImage *resultImage = [bgImage imageByCompositingOverImage:frontImage];
    return resultImage;
}

- (CIImage *)image:(CIImage *)image applyWithTransfrom:(CGAffineTransform)transform {
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
    [filter setValue:image forKey:@"inputImage"];
    [filter setValue:[NSValue valueWithCGAffineTransform:transform] forKey:@"inputTransform"];
    CIImage *outputImage = filter.outputImage;
    if (outputImage) {
        return outputImage;
    }
    return image;
}

@end


@implementation BoundingUpTransition

- (CIImage *)renderImageWithForegroundImage:(CIImage *)foregroundImage backgroundImage:(CIImage *)backgroundImage forTweenFactor:(CGFloat)tween renderSize:(CGSize)renderSize {
    tween = [TimingFunctionFactory quadraticEaseInOutWithP:tween];
    CGFloat height = renderSize.height;
    CGAffineTransform offsetTransform = CGAffineTransformMakeTranslation(0, height*tween);
    CIImage *bgImage = [self image:backgroundImage applyWithTransfrom:offsetTransform];
    
    CGFloat factor = 0.5 -ABS((0.5-tween));
    CGFloat scale = 1 + (factor * 2 * 0.1);
    
    CGAffineTransform foregroundTransform = CGAffineTransformMakeTranslation(0, height*(-1+tween));
    foregroundTransform = CGAffineTransformScale(foregroundTransform, scale, scale);
    CIImage *frontImage = [self image:foregroundImage applyWithTransfrom:foregroundTransform];
    
    CIImage *resultImage = [frontImage imageByCompositingOverImage:bgImage];
    return resultImage;
}

- (CIImage *)image:(CIImage *)image applyWithTransfrom:(CGAffineTransform)transform {
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
    [filter setValue:image forKey:@"inputImage"];
    [filter setValue:[NSValue valueWithCGAffineTransform:transform] forKey:@"inputTransform"];
    CIImage *outputImage = filter.outputImage;
    if (outputImage) {
        return outputImage;
    }
    return image;
}

@end


@implementation FadeTransition

- (CIImage *)renderImageWithForegroundImage:(CIImage *)foregroundImage backgroundImage:(CIImage *)backgroundImage forTweenFactor:(CGFloat)tween renderSize:(CGSize)renderSize {
    CGFloat backgroundAlpha = 0.0;
    CGFloat alpha = (0.5-tween)*2;
    if (alpha > 0) {
        backgroundAlpha = alpha;
    }
    
    CGFloat foregroundAlpha = 0.0;
    CGFloat foreAlpha = (tween - 0.5) * 2;
    if (foreAlpha > 0) {
        foregroundAlpha = foreAlpha;
    }
    
    CIImage *frontImage = [foregroundImage applyAlpha:foregroundAlpha];
    CIImage *bgImage = [backgroundImage applyAlpha:backgroundAlpha];
    
    CIImage *resultImage = [frontImage imageByCompositingOverImage:bgImage];
    return resultImage;
}

@end
