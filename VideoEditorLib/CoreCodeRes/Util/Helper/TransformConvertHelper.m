//
//  TransformConvertHelper.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/14/21.
//

#import "TransformConvertHelper.h"

@implementation TransformConvertHelper

+ (CGAffineTransform)transformBySourceRect:(CGRect)sourceRect aspectFitInRect:(CGRect)aspectFitInRect {
    CGRect fitRect = [self sourceRect:sourceRect aspectFitInRect:aspectFitInRect];
    CGFloat xRatio = fitRect.size.width / sourceRect.size.width;
    CGFloat yRatio = fitRect.size.height / sourceRect.size.height;
    
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(fitRect.origin.x - sourceRect.origin.x * xRatio, fitRect.origin.y - sourceRect.origin.y * yRatio);
    return CGAffineTransformScale(translateTransform, xRatio, yRatio);
}

+ (CGAffineTransform)transformBySourceRect:(CGRect)sourceRect aspectFillInRect:(CGRect)aspectFitInRect {
    CGRect fitRect = [self sourceRect:sourceRect aspectFillInRect:aspectFitInRect];
    CGFloat xRatio = fitRect.size.width / sourceRect.size.width;
    CGFloat yRatio = fitRect.size.height / sourceRect.size.height;
    
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(fitRect.origin.x - sourceRect.origin.x * xRatio, fitRect.origin.y - sourceRect.origin.y * yRatio);
    return CGAffineTransformScale(translateTransform, xRatio, yRatio);
}


#pragma mark - Extension CGRect
+(CGRect)sourceRect:(CGRect)sourceRect aspectFitInRect:(CGRect)rect {
    CGSize size = [self sourceSize:sourceRect.size aspectFitInSize:rect.size];
    CGFloat x = rect.origin.x + (rect.size.width - size.width)/2;
    CGFloat y = rect.origin.y + (rect.size.height - size.height)/2;
    return CGRectMake(x, y, size.width, size.height);
}

+(CGRect)sourceRect:(CGRect)sourceRect aspectFillInRect:(CGRect)rect {
    CGSize size = [self sourceSize:sourceRect.size aspectFillInSize:rect.size];
    CGFloat x = rect.origin.x + (rect.size.width - size.width)/2;
    CGFloat y = rect.origin.y + (rect.size.height - size.height)/2;
    return CGRectMake(x, y, size.width, size.height);
}


#pragma mark - Extension CGSize
+(CGSize)sourceSize:(CGSize)sourceSize aspectFitInSize:(CGSize)size {
    CGSize aspectFitSize = size;
    CGFloat widthRatio = size.width / sourceSize.width;
    CGFloat heightRatio = size.height / sourceSize.height;
    if (heightRatio < widthRatio) {
        aspectFitSize.width = round(heightRatio * sourceSize.width);
    }else {
        aspectFitSize.height = round(widthRatio * sourceSize.height);
    }
    return aspectFitSize;
}

+(CGSize)sourceSize:(CGSize)sourceSize aspectFillInSize:(CGSize)size {
    CGSize aspectFitSize = size;
    CGFloat widthRatio = size.width / sourceSize.width;
    CGFloat heightRatio = size.height / sourceSize.height;
    if (heightRatio > widthRatio) {
        aspectFitSize.width = round(heightRatio * sourceSize.width);
    }else {
        aspectFitSize.height = round(widthRatio * sourceSize.height);
    }
    return aspectFitSize;
}

@end
