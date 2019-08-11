#import <UIKit/UIKit.h>
@class XXJPieView;
@protocol XXJPieViewDataSource <NSObject>
@required
- (NSArray *)percentsForPieView:(XXJPieView *)pieView;
- (NSArray *)typesForPieView:(XXJPieView *)pieView;
- (NSArray *)colorsForPieView:(XXJPieView *)pieView;
@end
@interface XXJPieView : UIView
@property (weak, nonatomic) id<XXJPieViewDataSource> dataSource;
- (void)reloadData;
- (void)removeAllLabel;
@end
