#import "XXJAllHistoryViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Account.h"
#import "XXJAllHistoryTableViewCell.h"
#import "XXJMonthHIstoryViewController.h"
@interface XXJAllHistoryViewController () <UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *totalDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainMoneyLabel;
@property (weak, nonatomic) IBOutlet UITableView *monthTableView;
@property (strong, nonatomic) NSArray *dataArray; 
@property (strong, nonatomic) NSMutableArray *monthIncome; 
@property (strong, nonatomic) NSMutableArray *monthExpense; 
@property (assign, nonatomic) double totalIncome; 
@property (assign, nonatomic) double totalExpense; 
@property (strong, nonatomic) NSMutableArray *uniqueDateArray; 
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end
@implementation XXJAllHistoryViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.monthTableView.dataSource = self;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    self.monthIncome = [NSMutableArray array];
    self.monthExpense = [NSMutableArray array];
    [self judgeFirstLoadThisView];
}
- (void)judgeFirstLoadThisView {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"haveLoadedAZXAllHistoryViewController"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"教學" message:@"首頁顯示所有月份的帳單總額，點擊相應月份查看該月份所有天數的詳細內容，手指左滑可刪除相應行的記錄" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [defaults setBool:YES forKey:@"haveLoadedAZXAllHistoryViewController"];
        }];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchData];
    [self filterUniqueDate];
    [self calculateMonthsMoney];
    [self setTotalLabel];
    [self.monthTableView reloadData];
}
- (void)fetchData {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSError *error = nil;
    self.dataArray = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
}
- (void)filterUniqueDate {
    NSMutableArray *dateArray = [NSMutableArray array];
    for (Account *account in self.dataArray) {
        [dateArray addObject:[account.date substringToIndex:7]];
    }
    NSSet *set = [NSSet setWithArray:[dateArray copy]];
    NSArray *sortDesc = @[[[NSSortDescriptor alloc] initWithKey:nil ascending:YES]];
    self.uniqueDateArray = [NSMutableArray arrayWithArray:[set sortedArrayUsingDescriptors:sortDesc]];
}
- (void)calculateMonthsMoney {
    double tmpTotalIncome = 0;
    double tmpTotalExpense = 0;
    NSMutableArray *tmpMonthIncome = [NSMutableArray array];
    NSMutableArray *tmpMonthExpense = [NSMutableArray array];
    for (NSInteger i = 0; i < self.uniqueDateArray.count; i++) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@", self.uniqueDateArray[i]]];
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
        double income = 0;
        double expense = 0;
        for (Account *account in results) {
            if ([account.incomeType isEqualToString:@"income"]) {
                income += [account.money doubleValue];
            } else {
                expense += [account.money doubleValue];
            }
        }
        tmpTotalIncome += income;
        tmpTotalExpense += expense;
        [tmpMonthIncome addObject:[NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:income]]];
        [tmpMonthExpense addObject:[NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:expense]]];
    }
    self.totalIncome = tmpTotalIncome;
    self.totalExpense = tmpTotalExpense;
    self.monthIncome = tmpMonthIncome;
    self.monthExpense = tmpMonthExpense;
}
- (void)setTotalLabel {
    NSString *incomeString = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalIncome]];
    NSString *expenseString = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalExpense]];
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"總收入: %@  總支出: %@", incomeString, expenseString]];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 4)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(5, incomeString.length)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(5 + incomeString.length + 2, 4)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(5 + incomeString.length + 2 + 5, expenseString.length)];
    [self.totalDetailLabel setAttributedText:mutString];
    double remainMoney = self.totalIncome - self.totalExpense;
    self.remainMoneyLabel.text = [NSString stringWithFormat:@"結餘: %@", [NSNumber numberWithDouble:remainMoney]];
}
#pragma UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueDateArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXJAllHistoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"monthAccountCell" forIndexPath:indexPath];
    cell.date.text = self.uniqueDateArray[indexPath.row];
    NSMutableAttributedString * mutString = [self configMoneyLabelWithIndexPath:indexPath];
    [cell.money setAttributedText:mutString];
    return cell;
}
- (NSMutableAttributedString *)configMoneyLabelWithIndexPath:(NSIndexPath *)indexPath {
    NSString  *income = self.monthIncome[indexPath.row];
    NSString *incomeString = [@"收入: " stringByAppendingString:income];
    for (NSInteger i = income.length; i < 7; i++) {
        incomeString = [incomeString stringByAppendingString:@" "];
    }
    NSString *expense = self.monthExpense[indexPath.row];
    NSString *expenseString = [@" 支出: " stringByAppendingString:expense];
    for (NSInteger i = expense.length; i < 7; i++) {
        expenseString = [expenseString stringByAppendingString:@" "];
    }
    NSString *moneyString = [incomeString stringByAppendingString:expenseString];
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:moneyString];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 3)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(4, 7)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(12, 3)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(16, 7)];
    return mutString;
}
#pragma mark - UITabelView Delegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@", self.uniqueDateArray[indexPath.row]]];
        NSError *error = nil;
        NSArray *accountToBeDeleted = [self.managedObjectContext executeFetchRequest:request error:&error];
        for (Account *account in accountToBeDeleted) {
            [self.managedObjectContext deleteObject:account];
        }
        [self.uniqueDateArray removeObjectAtIndex:indexPath.row];
        [self.monthTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self calculateMonthsMoney];
        [self setTotalLabel];
        [self.monthTableView reloadData];
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @" 刪除 ";
}
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showMonthDetail"]) {
        if ([[segue destinationViewController] isKindOfClass:[XXJMonthHIstoryViewController class]]) {
            XXJMonthHIstoryViewController *viewController = [segue destinationViewController];
            NSIndexPath *indexPath = [self.monthTableView indexPathForSelectedRow];
            viewController.date = self.uniqueDateArray[indexPath.row];
        }
    }
}
@end
