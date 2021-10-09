//
//  BaseKeyFrameValue.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/18/21.
//

#import "BaseKeyFrameValue.h"
#import "CIImage+Helper.h"

@implementation BaseKeyFrameValue

- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage param:(KeyframeValueParam *)param {
    NSAssert(NO, @"Sub class imp.");
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[super class] allocWithZone:zone];
}

@end


@implementation TransformKeyframeValue

- (instancetype)init {
    if (self = [super init]) {
        _scale = 1.0;
        _rotation = 0.0;
        _translation = CGPointZero;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    TransformKeyframeValue *value = [[self class] allocWithZone:zone];
    value.scale = self.scale;
    value.rotation = self.rotation;
    value.translation = self.translation;
    return value;
}

- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage param:(KeyframeValueParam *)param {
    if (!param.toValue || ![param.toValue isKindOfClass:[TransformKeyframeValue class]]) {
        return sourceImage;
    }
    
    CIImage *finalImage = sourceImage;
    
    TransformKeyframeValue *toValue = (TransformKeyframeValue *)param.toValue;
    TransformKeyframeValue *fromValue = (TransformKeyframeValue *)param.fromValue;
    if (!fromValue) {
        fromValue = [[TransformKeyframeValue alloc] init];
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGFloat translatX = -(sourceImage.extent.origin.x + sourceImage.extent.size.width/2);
    CGFloat translatY = -(sourceImage.extent.origin.y + sourceImage.extent.size.height/2);
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(translatX, translatY);
    transform = CGAffineTransformConcat(transform, translateTransform);
    
    CGFloat scale = fromValue.scale + (toValue.scale - fromValue.scale) * param.tween;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(scale, scale));

    CGFloat rotation = fromValue.rotation + (toValue.rotation - fromValue.rotation) * param.tween;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeRotation(rotation));

    CGFloat translationX = fromValue.translation.x + (toValue.translation.x - fromValue.translation.x) * param.tween;
    CGFloat translationY = fromValue.translation.y + (toValue.translation.y - fromValue.translation.y) * param.tween;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(translationX, translationY));

    CGFloat extentX = sourceImage.extent.origin.x + sourceImage.extent.size.width/2;
    CGFloat extentY = sourceImage.extent.origin.y + sourceImage.extent.size.height/2;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(extentX, extentY));
    
    finalImage = [sourceImage imageByApplyingTransform:transform];
    
    return finalImage;
}

@end


@implementation OpacityKeyframeValue

- (instancetype)init {
    if (self = [super init]) {
        _opacity = 1.0;
        
    }
    return self;
}

#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    OpacityKeyframeValue *value = [[self class] allocWithZone:zone];
    value.opacity = self.opacity;
    return value;
}


#pragma mark - KeyframeValue
- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage param:(KeyframeValueParam *)param {
    if (!param.toValue || ![param.toValue isKindOfClass:[OpacityKeyframeValue class]]) {
        return sourceImage;
    }
    
    CIImage *finalImage = sourceImage;
    
    OpacityKeyframeValue *toValue = (OpacityKeyframeValue *)param.toValue;
    OpacityKeyframeValue *fromValue = (OpacityKeyframeValue *)param.fromValue;
    if (!fromValue) {
        fromValue = [[OpacityKeyframeValue alloc] init];
    }
    
    CGFloat toOpacity = toValue.opacity;
    CGFloat fromOpacity = fromValue.opacity;
    CGFloat opacity = fromOpacity + (toOpacity - fromOpacity) * param.tween;
    
    finalImage = [sourceImage applyAlpha:opacity];
    
    return finalImage;
}

@end


#pragma mark - KeyframeValueParam
@implementation KeyframeValueParam



@end
