//
//  OCRoundedImageResponseSerializer.m
//  iOCNews
//
//  Created by Peter Hedlund on 7/14/15.
//  Copyright (c) 2015 Peter Hedlund. All rights reserved.
//

#import "OCRoundedImageResponseSerializer.h"

@interface OCRoundedImageResponseSerializer ()
@property (readwrite, nonatomic, assign) CGSize size;
@end

@implementation OCRoundedImageResponseSerializer
#pragma mark - AFURLResponseSerializer

+ (instancetype)serializerWithSize:(CGSize)size {
    OCRoundedImageResponseSerializer *serializer = [[self alloc] init];
    serializer.size = size;
    
    return serializer;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {

    id responseObject = [super responseObjectForResponse:response data:data error:error];
    if (!responseObject) {
        return nil;
    }
    
    UIImage *image = [UIImage imageWithCGImage:[responseObject CGImage]];
    UIImage *newImage;
    
    if (image) {
        CGFloat width = image.size.width;
        CGFloat height = image.size.height;
        CGFloat targetWidth = self.size.width;
        CGFloat targetHeight = self.size.height;
        CGFloat scaleFactor = 0.0;
        CGFloat scaledWidth = targetWidth;
        CGFloat scaledHeight = targetHeight;
        CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
        
        if (!CGSizeEqualToSize(image.size, self.size)) {
            CGFloat widthFactor = targetWidth / width;
            CGFloat heightFactor = targetHeight / height;
            
            if (widthFactor > heightFactor) {
                scaleFactor = widthFactor; // scale to fit height
            } else {
                scaleFactor = heightFactor; // scale to fit width
            }
            
            scaledWidth  = width * scaleFactor;
            scaledHeight = height * scaleFactor;
            
            // center the image
            if (widthFactor > heightFactor) {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            } else {
                if (widthFactor < heightFactor) {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                }
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0);
        
        CGRect thumbnailRect = CGRectZero;
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width  = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        
        int radius;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            radius = 18;
        } else {
            radius = 9;
        }
        
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.size.width, self.size.width) cornerRadius:radius] addClip];
        
        [image drawInRect:thumbnailRect];
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }

    return newImage;
}
@end
