#import "XXJPieView.h"
@interface XXJPieView ()
@property (strong, nonatomic) NSArray *colorArray;
@property (strong, nonatomic) NSArray *typeArray;
@property (strong, nonatomic) NSArray *percentArray;
@property (strong, nonatomic) NSMutableArray *labelArray;
@end
@implementation XXJPieView
- (void)drawRect:(CGRect)rect {
    [[UIColor whiteColor] set];
    UIRectFill(rect);
    self.labelArray = [NSMutableArray array];
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(percentsForPieView:)] && [self.dataSource respondsToSelector:@selector(typesForPieView:)] && [self.dataSource respondsToSelector:@selector(colorsForPieView:)]) {
        self.typeArray = [self.dataSource typesForPieView:self];
        self.percentArray = [self.dataSource percentsForPieView:self];
        self.colorArray = [self.dataSource colorsForPieView:self];
        NSMutableArray *startAngleArray = [NSMutableArray array];
        CGFloat angle = 0;
        for (NSInteger i = 0; i < self.percentArray.count; i++) {
            [startAngleArray addObject:[NSNumber numberWithDouble:angle]];
            angle += [self.percentArray[i] doubleValue] * 2 * M_PI / 100;
        }
        for (NSInteger j = 0; j < self.typeArray.count; j++) {
            [self drawSectorWithStartAngle:[startAngleArray[j] doubleValue] Percent:[self.percentArray[j] doubleValue]/100 Type:self.typeArray[j] Color:self.colorArray[j]];
        }
    }
}
- (void)drawSectorWithStartAngle:(double)startAngle Percent:(double)percent Type:(NSString *)type Color:(UIColor *)color {
    CGFloat radius = self.frame.size.width > self.frame.size.height? self.frame.size.height/2 : self.frame.size.width/2;  
    CGPoint center = self.center;
    center.x -= self.frame.origin.x;
    center.y -= self.frame.origin.y;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:center];
    [path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:startAngle + 2*M_PI*percent clockwise:YES];
    [path addLineToPoint:center];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    label.text = type;
    label.textColor = [UIColor blackColor];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    label.textAlignment = NSTextAlignmentCenter;
    [label sizeToFit];
    if ((percent < 0.5 && label.frame.size.width * fabs(sin(startAngle + M_PI*percent)) > sqrt(2*(radius/2)*(radius/2) - 2*radius/2*radius/2*cos(2*M_PI*percent))) || percent < 0.03) {
        label.text = @"..";
    }
    CGFloat centerX = center.x + (radius/2*cos(startAngle + M_PI*percent));
    CGFloat centerY = center.y + (radius/2*sin(startAngle + M_PI*percent));
    label.center = CGPointMake(centerX, centerY);
    [self addSubview:label];
    [self.labelArray addObject:label]; 
    [color set];
    [path fill];
}
- (void)reloadData {
    [self setNeedsDisplay];
}
- (void)removeAllLabel {
    for (UILabel *label in self.labelArray) {
        [label removeFromSuperview];
    }
}
@end
