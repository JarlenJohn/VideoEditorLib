//
//  CIImage+Helper.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/10/21.
//

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface CIImage (Helper)

- (CIImage *)flipYCoordinate;

- (CIImage *)applyAlpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
