//
//  OCBadgeView.m
//  iOCNews
//
//  Created by Peter Hedlund on 1/14/14.
//  Copyright (c) 2014 Peter Hedlund. All rights reserved.
//

#import "OCBadgeView.h"

@implementation OCBadgeView

@synthesize value = _value;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGRect viewBounds = self.bounds;
	CGContextRef curContext = UIGraphicsGetCurrentContext();
	NSString* numberString = [NSString stringWithFormat:@"%lu", (unsigned long)self.value];
	CGSize numberSize = [numberString sizeWithAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16.0f]}];
    
    CGFloat arcRadius = ceil((numberSize.height + 2.0) / 2.0);
	CGFloat badgeWidthAdjustment = numberSize.width - numberSize.height / 2.0;
	CGFloat badgeWidth = 2.0 * arcRadius;
	
	if ( badgeWidthAdjustment > 0.0 ){
		badgeWidth += badgeWidthAdjustment;
	}
	
	CGMutablePathRef badgePath = CGPathCreateMutable();
	CGPathMoveToPoint(badgePath, NULL, arcRadius, 0);
	CGPathAddArc(badgePath, NULL, arcRadius, arcRadius, arcRadius, 3.0 * M_PI_2, M_PI_2, YES);
	CGPathAddLineToPoint(badgePath, NULL, badgeWidth - arcRadius, 2.0 * arcRadius);
	CGPathAddArc(badgePath, NULL, badgeWidth - arcRadius, arcRadius, arcRadius, M_PI_2, 3.0 * M_PI_2, YES);
	CGPathAddLineToPoint(badgePath, NULL, arcRadius, 0);
    
	CGRect badgeRect = CGPathGetBoundingBox(badgePath);
	
	badgeRect.origin.x = 0;
	badgeRect.origin.y = 0;
	badgeRect.size.width = ceil(badgeRect.size.width);
	badgeRect.size.height = ceil(badgeRect.size.height);
	
	CGContextSaveGState(curContext);
	CGContextSetLineWidth(curContext, 0.0);
	CGContextSetStrokeColorWithColor(curContext, [UIColor colorWithRed:0.58f green:0.61f blue:0.65f alpha:1.0f].CGColor);
	CGContextSetFillColorWithColor(curContext, [UIColor colorWithRed:0.58f green:0.61f blue:0.65f alpha:1.0f].CGColor);
	
	CGPoint ctm = CGPointMake((viewBounds.size.width - badgeRect.size.width) - 10, round((viewBounds.size.height - badgeRect.size.height) / 2));
	CGContextTranslateCTM(curContext, ctm.x, ctm.y);
	
	CGContextBeginPath(curContext);
	CGContextAddPath(curContext, badgePath);
	CGContextClosePath(curContext);
	CGContextDrawPath(curContext, kCGPathFillStroke);
    
	CGContextRestoreGState(curContext);
	CGPathRelease(badgePath);
	
	CGContextSaveGState(curContext);
	CGPoint textPt = CGPointMake(ctm.x + (badgeRect.size.width - numberSize.width) / 2 , ctm.y + (badgeRect.size.height - numberSize.height) / 2);
	[numberString drawAtPoint:textPt withAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f],
                                                      NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
	CGContextRestoreGState(curContext);
}

- (void)setValue:(NSUInteger)inValue {
	_value = inValue;
    self.hidden = (_value == 0);
	[self setNeedsDisplay];
}

@end
