#import "Account.h"
NS_ASSUME_NONNULL_BEGIN
@interface Account (CoreDataProperties)
@property (nullable, nonatomic, retain) NSString *date;
@property (nullable, nonatomic, retain) NSString *detail;
@property (nullable, nonatomic, retain) NSString *incomeType;
@property (nullable, nonatomic, retain) NSString *money;
@property (nullable, nonatomic, retain) NSString *type;
@end
NS_ASSUME_NONNULL_END
