//
//  TransformConvertHelper.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/14/21.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface TransformConvertHelper : NSObject

+ (CGAffineTransform)transformBySourceRect:(CGRect)sourceRect aspectFitInRect:(CGRect)aspectFitInRect;

+ (CGAffineTransform)transformBySourceRect:(CGRect)sourceRect aspectFillInRect:(CGRect)aspectFitInRect;


@end

NS_ASSUME_NONNULL_END
