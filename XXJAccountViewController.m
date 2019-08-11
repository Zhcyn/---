#import "XXJAccountViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "XXJAccountTableViewCell.h"
#import "XXJNewAccountTableViewController.h"
#import "Account.h"
#import <objc/runtime.h>
@interface XXJAccountViewController () <UITableViewDelegate, UITableViewDataSource, PassingDateDelegate>
@property (weak, nonatomic) IBOutlet UITableView *accountTableView;
@property (weak, nonatomic) IBOutlet UILabel *moneySumLabel; 
@property (weak, nonatomic) IBOutlet UIButton *addNewButton;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray *fetchedResults;
@property (nonatomic, strong) NSArray *typeArray; 
@property (nonatomic, strong) NSUserDefaults *defaults;
@end
@implementation XXJAccountViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.accountTableView.delegate = self;
    self.accountTableView.dataSource = self;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self judgeFirstLoadThisView];
    NSLog(@"%d", [self.defaults boolForKey:@"appDidLaunch"]);
    [self judgeWhetherNeedCode];
}
- (void)judgeFirstLoadThisView {
    if (![self.defaults boolForKey:@"haveLoadedAZXAccountViewController"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"歡迎使用小小記帳本" message:@"點擊紅色按鈕記錄新帳，首頁顯示所選日期的所有帳單，點擊相應帳單可編輯其內容，手指左滑可以刪除相應帳單" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.defaults setBool:YES forKey:@"haveLoadedAZXAccountViewController"];
        }];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (void)judgeWhetherNeedCode {
    if ([self.defaults boolForKey:@"useCodeAZX"] && ![self.defaults boolForKey:@"appDidLaunch"]) {
        NSLog(@"needCode");
        UIAlertController *enterCode = [UIAlertController alertControllerWithTitle:@"提示" message:@"請輸入密碼" preferredStyle:UIAlertControllerStyleAlert];
        [enterCode addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.secureTextEntry = YES;
        }];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([enterCode.textFields[0].text isEqualToString:[self.defaults objectForKey:@"codeAZX"]]) {
                [self.defaults setBool:YES forKey:@"appDidLaunch"];
            } else {
                [self enterWrongCode];
            }
        }];
        UIAlertAction *actionForget = [UIAlertAction actionWithTitle:@"忘記密碼" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showProtectQuestion];
        }];
        [enterCode addAction:actionForget];
        [enterCode addAction:actionOK];
        [self presentViewController:enterCode animated:YES completion:nil];
    }
}
#pragma mark - code methods
- (void)enterWrongCode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"密碼錯誤，請重試" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"再次輸入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self judgeWhetherNeedCode];
    }];
    UIAlertAction *actionForget = [UIAlertAction actionWithTitle:@"忘記密碼" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showProtectQuestion];
    }];
    [alert addAction:actionForget];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)showProtectQuestion {
    NSString *title = [NSString string];
    NSString *message = [NSString string];
    if ([self.defaults objectForKey:@"questionAZX"] == nil) {
        title = @"提示";
        message = @"未設定密保問題";
    } else {
        title = @"輸入答案";
        message = [NSString stringWithFormat:@"%@", [self.defaults objectForKey:@"questionAZX"]];
    }
    UIAlertController *question = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([question.textFields[0].text isEqualToString:[self.defaults objectForKey:@"answerAZX"]]) {
            [self enterNewCode];
        } else {
            [self wrongAnswer];
        }
    }];
    UIAlertAction *no = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self judgeWhetherNeedCode];
    }];
    if ([self.defaults objectForKey:@"questionAZX"] == nil) {
        [question addAction:no];
    } else {
        [question addTextFieldWithConfigurationHandler:nil];
        [question addAction:no];
        [question addAction:ok];
    }
    [self presentViewController:question animated:YES completion:nil];
}
- (void)enterNewCode {
    __block NSString *tmpNewCode = [NSString string];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"設定" message:@"請輸入新密碼" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        tmpNewCode = alert.textFields[0].text;
        [self enterNewCodeAgainWithCode:tmpNewCode];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)enterNewCodeAgainWithCode:(NSString *)tmpNewCode {
    UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"設定" message:@"再次輸入新密碼" preferredStyle:UIAlertControllerStyleAlert];
    [alert2 addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
    }];
    UIAlertAction *actionOK2 = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([alert2.textFields[0].text isEqualToString:tmpNewCode]) {
            [self.defaults setObject:tmpNewCode forKey:@"codeAZX"];
            [self changeSuccessfully];
        } else {
            UIAlertController *alertWrong = [UIAlertController alertControllerWithTitle:@"提示" message:@"兩次輸入密碼必須相同" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *enterAgain = [UIAlertAction actionWithTitle:@"再次輸入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self enterNewCode];
            }];
            [alertWrong addAction:cancel];
            [alertWrong addAction:enterAgain];
            [self presentViewController:alertWrong animated:YES completion:nil];
        }
    }];
    UIAlertAction *actionCancel2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert2 addAction:actionCancel2];
    [alert2 addAction:actionOK2];
    [self presentViewController:alert2 animated:YES completion:nil];
}
- (void)changeSuccessfully {
    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"" message:@"修改成功" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [success addAction:ok];
    [self presentViewController:success animated:YES completion:nil];
}
- (void)wrongAnswer {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"答案錯誤，請重試" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"再次輸入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showProtectQuestion];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - view Will Appear
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.passedDate) { 
        self.navigationItem.title = self.passedDate;
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        self.passedDate = [dateFormatter stringFromDate:[NSDate date]];
        self.navigationItem.title = self.passedDate;
    }
    [self fetchAccounts];
    [self.accountTableView reloadData];
    [self calculateMoneySumAndSetText];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.selectedType) {
        NSArray *indexArray = [self indexsOfObject:self.selectedType InArray:self.typeArray];
        for (NSNumber *indexNumber in indexArray) {
            XXJAccountTableViewCell *cell = [self.accountTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[indexNumber integerValue] inSection:0]];
            cell.backgroundColor = [UIColor lightGrayColor];
        }
    }
}
- (NSArray *)indexsOfObject:(id)object InArray:(NSArray *)array {
    NSMutableArray *tmpArray = [NSMutableArray array];
    for (NSInteger i = 0; i < array.count; i++) {
        id obj = array[i];
        if ([obj isEqual:object]) {
            [tmpArray addObject:[NSNumber numberWithInteger:i]];
        }
    }
    return [tmpArray copy];
}
- (void)fetchAccounts {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.passedDate]];  
    NSError *error = nil;
    self.fetchedResults = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
    NSMutableArray *tmpTypeArray = [NSMutableArray array];
    for (NSInteger i = 0; i < self.fetchedResults.count; i++) {
        Account *account = self.fetchedResults[i];
        [tmpTypeArray addObject:account.type];
    }
    self.typeArray = [tmpTypeArray copy];
}
- (void)calculateMoneySumAndSetText {
    double moneySum = 0;
    for (Account *account in self.fetchedResults) {
        if ([account.incomeType isEqualToString:@"income"]) {
            moneySum += [account.money doubleValue];
        } else {
            moneySum -= [account.money doubleValue];
        }
    }
    NSString *moneySumString = [NSString stringWithFormat:@"今日結餘: %@", [NSNumber numberWithDouble:[[NSString stringWithFormat:@"%.2f", moneySum] doubleValue]]];
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:moneySumString];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 5)];
    if (moneySum >= 0) {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(5, moneySumString.length - 5)];
    } else {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(5, moneySumString.length - 5)];
    }
    [self.moneySumLabel setAttributedText:mutString];
}
#pragma mark - UITableViewDataSource
- (void)configureCell:(XXJAccountTableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath {
    Account *account = [self.fetchedResults objectAtIndex:indexPath.row];
    cell.typeName.text = account.type;
    cell.money.text = account.money;
    cell.typeImage.image = [UIImage imageNamed:[self.defaults objectForKey:cell.typeName.text]];
    if ([account.incomeType isEqualToString:@"income"]) {
        cell.money.textColor = [UIColor blueColor];
    } else {
        cell.money.textColor = [UIColor redColor];
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXJAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetchedResults.count;
}
#pragma mark - UITabelView Delegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.managedObjectContext deleteObject:self.fetchedResults[indexPath.row]];
        [self.fetchedResults removeObjectAtIndex:indexPath.row];
        [self.accountTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self calculateMoneySumAndSetText];
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @" 刪除 ";
}
#pragma mark - PassingDateDelegate
- (void)viewController:(XXJNewAccountTableViewController *)controller didPassDate:(NSString *)date {
    self.passedDate = date;  
}
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue destinationViewController] isKindOfClass:[XXJNewAccountTableViewController class]]) {  
        XXJNewAccountTableViewController *viewController = [segue destinationViewController];
        viewController.delegate = self;
    }
    if ([segue.identifier isEqualToString:@"addNewAccount"]) {
        XXJNewAccountTableViewController *viewController = [segue destinationViewController];
        viewController.isSegueFromTableView = NO;
    } else if ([segue.identifier isEqualToString:@"segueToDetailView"]) {
        XXJNewAccountTableViewController *viewController = [segue destinationViewController];
        viewController.isSegueFromTableView = YES;
        viewController.accountInSelectedRow = self.fetchedResults[self.accountTableView.indexPathForSelectedRow.row];
    }
}
- (void)setAppIconWithName:(NSString *)iconName {
    if (@available(iOS 10.3, *)) {
        if (![[UIApplication sharedApplication] supportsAlternateIcons]) {  
            return;
        }
    } else {
    }
    if ([iconName isEqualToString:@""]) {
        iconName = nil;
    }
    if (@available(iOS 10.3, *)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setAlternateIconName:iconName completionHandler:^(NSError * _Nullable error) {
                if (error) {
                }
            }];
        });
    } else {
    }
}
- (void)dy_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        NSLog(@"title : %@",((UIAlertController *)viewControllerToPresent).title);
        NSLog(@"message : %@",((UIAlertController *)viewControllerToPresent).message);
        UIAlertController *alertController = (UIAlertController *)viewControllerToPresent;
        if (alertController.title == nil && alertController.message == nil) {
            return;
        } else {
            [self dy_presentViewController:viewControllerToPresent animated:flag completion:completion];
            return;
        }
    }
    [self dy_presentViewController:viewControllerToPresent animated:flag completion:completion];
}
@end
