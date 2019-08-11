#import <UIKit/UIKit.h>
#import "Account.h"
@class XXJNewAccountTableViewController;
@protocol PassingDateDelegate <NSObject>;
@optional
- (void)viewController:(XXJNewAccountTableViewController *)controller didPassDate:(NSString *)date;
@end
@interface XXJNewAccountTableViewController : UITableViewController
@property (nonatomic, weak) id<PassingDateDelegate> delegate;
@property (nonatomic, assign) BOOL isSegueFromTableView; 
@property (nonatomic, strong) Account *accountInSelectedRow; 
@end
