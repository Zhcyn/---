#import "XXJMonthHIstoryViewController.h"
#import "XXJAllHistoryTableViewCell.h"
#import "AppDelegate.h"
#import "Account.h"
#import "XXJAccountViewController.h"
#import <CoreData/CoreData.h>
@interface XXJMonthHIstoryViewController () <UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *TotalMoneyLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainMoneyLabel;
@property (weak, nonatomic) IBOutlet UITableView *dayTableView;
@property (strong, nonatomic) NSArray *dataArray; 
@property (strong, nonatomic) NSMutableArray *dayIncome; 
@property (strong, nonatomic) NSMutableArray *dayExpense; 
@property (nonatomic, assign) double totalIncome; 
@property (nonatomic, assign) double totalExpense; 
@property (strong, nonatomic) NSMutableArray *uniqueDateArray; 
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end
@implementation XXJMonthHIstoryViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.dayTableView.dataSource = self;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    self.dayIncome = [NSMutableArray array];
    self.dayExpense = [NSMutableArray array];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = self.date;
    [self fetchData];
    [self filterUniqueDate];
    [self calculateDayMoney];
    [self setTotalLabel];
    [self.dayTableView reloadData];
}
- (void)fetchData {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@", self.date]];
    NSError *error = nil;
    self.dataArray = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
}
- (void)filterUniqueDate {
    NSMutableArray *dateArray = [NSMutableArray array];
    for (Account *account in self.dataArray) {
        [dateArray addObject:account.date];
    }
    NSSet *set = [NSSet setWithArray:[dateArray copy]];
    NSArray *SortDesc = @[[[NSSortDescriptor alloc] initWithKey:nil ascending:YES]];
    self.uniqueDateArray = [NSMutableArray arrayWithArray:[set sortedArrayUsingDescriptors:SortDesc]];
}
- (void)calculateDayMoney {
    double tmpTotalIncome = 0;
    double tmpTotalExpense = 0;
    NSMutableArray *tmpDayIncome = [NSMutableArray array];
    NSMutableArray *tmpDayExpense = [NSMutableArray array];
    for (NSInteger i = 0; i < self.uniqueDateArray.count; i++) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.uniqueDateArray[i]]];
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
        [tmpDayIncome addObject:[NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:income]]];
        [tmpDayExpense addObject:[NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:expense]]];
    }
    self.totalIncome = tmpTotalIncome;
    self.totalExpense = tmpTotalExpense;
    self.dayIncome = tmpDayIncome;
    self.dayExpense = tmpDayExpense;
}
- (void)setTotalLabel {
    NSString *incomeString = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalIncome]];
    NSString *expenseString = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalExpense]];
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"本月收入: %@  本月支出: %@", incomeString, expenseString]];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 5)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(6, incomeString.length)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(6 + incomeString.length + 2, 5)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(6 + incomeString.length + 2 + 6, expenseString.length)];
    [self.TotalMoneyLabel setAttributedText:mutString];
    double remainMoney = self.totalIncome - self.totalExpense;
    self.remainMoneyLabel.text = [NSString stringWithFormat:@"结余: %@", [NSNumber numberWithDouble:remainMoney]];
}
#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueDateArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXJAllHistoryTableViewCell *cell = [self.dayTableView dequeueReusableCellWithIdentifier:@"dayAccountCell" forIndexPath:indexPath];
    NSString *fullDate = self.uniqueDateArray[indexPath.row];
    cell.date.text = [fullDate substringFromIndex:5];
    NSMutableAttributedString * mutString = [self configMoneyLabelWithIndexPath:indexPath];
    [cell.money setAttributedText:mutString];
    return cell;
}
- (NSMutableAttributedString *)configMoneyLabelWithIndexPath:(NSIndexPath *)indexPath {
    NSString  *income = self.dayIncome[indexPath.row];
    NSString *incomeString = [@"收入: " stringByAppendingString:income];
    for (NSInteger i = income.length; i < 7; i++) {
        incomeString = [incomeString stringByAppendingString:@" "];
    }
    NSString *expense = self.dayExpense[indexPath.row];
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
        [request setPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.uniqueDateArray[indexPath.row]]];
        NSError *error = nil;
        NSArray *accountToBeDeleted = [self.managedObjectContext executeFetchRequest:request error:&error];
        for (Account *account in accountToBeDeleted) {
            [self.managedObjectContext deleteObject:account];
        }
        [self.uniqueDateArray removeObjectAtIndex:indexPath.row];
        [self.dayTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self calculateDayMoney];
        [self setTotalLabel];
        [self.dayTableView reloadData];
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @" 删除 ";
}
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDayDetail"]) {
        if ([[segue destinationViewController] isKindOfClass:[XXJAccountViewController class]]) {
            XXJAccountViewController *viewController = [segue destinationViewController];
            NSIndexPath *indexPath = [self.dayTableView indexPathForSelectedRow];
            viewController.passedDate = self.uniqueDateArray[indexPath.row];
        }
    }
}
@end
