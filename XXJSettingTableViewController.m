#import "XXJSettingTableViewController.h"
#import "XXJOperateTypeTableViewController.h"
#import "XXJAddTypeViewController.h"
#import "AppDelegate.h"
#import "Account.h"
#import <CoreData/CoreData.h>
@interface XXJSettingTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *deleteAllLabel;
@property (weak, nonatomic) IBOutlet UISwitch *codeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *changeCode;
@property (weak, nonatomic) IBOutlet UILabel *codeProtectQuestion;
@property (strong, nonatomic) NSUserDefaults *defaults;
@end
@implementation XXJSettingTableViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self judgeFirstLoadThisView];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.defaults boolForKey:@"useCodeAZX"]) {
        self.changeCode.textColor = [UIColor blueColor];
        self.codeProtectQuestion.textColor = [UIColor blueColor];
        [self.codeSwitch setOn:YES];
    } else {
        self.codeSwitch.on = NO;
        if (!self.codeSwitch.isOn) {
            [self cellsInteractionWithSwitchOn:NO];
        }
    }
}
- (void)judgeFirstLoadThisView {
    if (![self.defaults boolForKey:@"haveLoadedAZXSettingTableViewController"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"教學" message:@"在設定頁面你可以開啓密碼保護，進行類別名稱管理" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.defaults setBool:YES forKey:@"haveLoadedAZXSettingTableViewController"];
        }];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (IBAction)switchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        self.changeCode.textColor = [UIColor blueColor];
        self.codeProtectQuestion.textColor = [UIColor blueColor];
        [self cellsInteractionWithSwitchOn:YES];
        [self alertInputNewCode];
        [self.defaults setBool:YES forKey:@"useCodeAZX"];
    } else {
        [self returnToSwitchOffStatus];
        [self.defaults setBool:NO forKey:@"useCodeAZX"];
    }
}
- (void)cellsInteractionWithSwitchOn:(BOOL)switchIsOn {
    if (switchIsOn) {
        for (NSInteger i = 1; i < 3; i++) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            cell.userInteractionEnabled = YES;
        }
    } else {
        for (NSInteger i = 1; i < 3; i++) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            cell.userInteractionEnabled = NO;
        }
    }
}
- (void)alertInputNewCode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"設定" message:@"請輸入新密碼" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        if ([self.defaults stringForKey:@"codeAZX"]) {
            textField.text = [self.defaults objectForKey:@"codeAZX"];
        }
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.defaults setObject:alert.textFields[0].text forKey:@"codeAZX"];
        [self askUserToSetCodeProtect];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.codeSwitch setOn:NO animated:YES];
        [self returnToSwitchOffStatus];
    }];
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)returnToSwitchOffStatus {
    self.changeCode.textColor = [UIColor lightGrayColor];
    self.codeProtectQuestion.textColor = [UIColor lightGrayColor];
    [self cellsInteractionWithSwitchOn:NO];
}
- (void)askUserToSetCodeProtect {
    UIAlertController *whetherSetCodeProtect = [UIAlertController alertControllerWithTitle:@"提示" message:@"設定密碼保護問題可以使您在忘記密碼時找回密碼" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:@"現在設定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setUpCodeProtectQuestion];
    }];
    UIAlertAction *no = [UIAlertAction actionWithTitle:@"以後再說" style:UIAlertActionStyleCancel handler:nil];
    [whetherSetCodeProtect addAction:no];
    [whetherSetCodeProtect addAction:yes];
    [self presentViewController:whetherSetCodeProtect animated:YES completion:nil];
}
- (void)setUpCodeProtectQuestion {
    __block UIAlertController *addProtectQuestion = [UIAlertController alertControllerWithTitle:@"設定" message:@"輸入問題及答案" preferredStyle:UIAlertControllerStyleAlert];
    [addProtectQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"設定問題";
    }];
    [addProtectQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"設定答案";
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (addProtectQuestion.textFields[0].text != nil && addProtectQuestion.textFields[1].text != nil) {
            [self.defaults setObject:addProtectQuestion.textFields[0].text forKey:@"questionAZX"];
            [self.defaults setObject:addProtectQuestion.textFields[1].text forKey:@"answerAZX"];
        } else {
            UIAlertController *remainder = [UIAlertController alertControllerWithTitle:@"提示" message:@"問題與答案都不能為空" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *enterAgain = [UIAlertAction actionWithTitle:@"再次輸入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self setUpCodeProtectQuestion];
            }];
            UIAlertAction *quit = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [remainder addAction:quit];
            [remainder addAction:enterAgain];
            [self presentViewController:remainder animated:YES completion:nil];
        }
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [addProtectQuestion addAction:actionCancel];
    [addProtectQuestion addAction:actionOK];
    [self presentViewController:addProtectQuestion animated:YES completion:nil];
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else if (section == 1) {
        return 3;
    } else {
        return 1;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.codeSwitch.isOn && indexPath.section == 0 && indexPath.row == 1) {
        [self alertChangeCode];
    } else if (self.codeSwitch.isOn && indexPath.section == 0 && indexPath.row == 2) {
        [self changeProtectQuestion];
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"全部資料刪除後將無法找回" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確定刪除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self deleteAllAccounts];
        }];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:actionCancel];
        [alert addAction:actionOK];
        [self presentViewController:alert animated:YES completion:^ {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    }
}
- (void)deleteAllAccounts {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSError *error = nil;
    NSArray *allAccounts = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
    for (Account *account in allAccounts) {
        [appDelegate.managedObjectContext deleteObject:account];
    }
}
#pragma mark - change Code and protect question methods
- (void)alertChangeCode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"設定" message:@"請輸入舊的密碼，以驗證身份" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確認" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([alert.textFields[0].text isEqualToString:[self.defaults objectForKey:@"codeAZX"]]) {
            [self enterNewCode];
        } else {
            [self wrongOldCode];
        }
    }];
    UIAlertAction *actionForget = [UIAlertAction actionWithTitle:@"忘記密碼" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showProtectQuestion];
    }];
    [alert addAction:actionForget];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
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
    [self presentViewController:alert animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
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
    [self presentViewController:alert2 animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}
- (void)wrongOldCode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"密碼錯誤，請重試" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"再次輸入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self alertChangeCode];
    }];
    UIAlertAction *actionForget = [UIAlertAction actionWithTitle:@"忘記密碼" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showProtectQuestion];
    }];
    [alert addAction:actionForget];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)showProtectQuestion {
    UIAlertController *question = [UIAlertController alertControllerWithTitle:@"輸入答案" message:[NSString stringWithFormat:@"%@", [self.defaults objectForKey:@"questionAZX"]] preferredStyle:UIAlertControllerStyleAlert];
    [question addTextFieldWithConfigurationHandler:nil];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([question.textFields[0].text isEqualToString:[self.defaults objectForKey:@"answerAZX"]]) {
            [self enterNewCode];
        } else {
            [self wrongAnswer];
        }
    }];
    UIAlertAction *no = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [question addAction:no];
    [question addAction:ok];
    [self presentViewController:question animated:YES completion:nil];
}
- (void)wrongAnswer {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"答案錯誤，請重試" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"再次輸入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showProtectQuestion];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    [self presentViewController:alert animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}
- (void)changeSuccessfully {
    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"" message:@"修改成功" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [success addAction:ok];
    [self presentViewController:success animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}
- (void)changeProtectQuestion {
    UIAlertController *changeQuestion = [UIAlertController alertControllerWithTitle:@"設定" message:@"修改問題與答案" preferredStyle:UIAlertControllerStyleAlert];
    [changeQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [self.defaults objectForKey:@"questionAZX"];
    }];
    [changeQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [self.defaults objectForKey:@"answerAZX"];
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.defaults setObject:changeQuestion.textFields[0].text forKey:@"questionAZX"];
        [self.defaults setObject:changeQuestion.textFields[1].text forKey:@"answerAZX"];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [changeQuestion addAction:actionCancel];
    [changeQuestion addAction:actionOK];
    [self presentViewController:changeQuestion animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addNewType"]) {
    } else if ([segue.identifier isEqualToString:@"changeType"]) {
        XXJOperateTypeTableViewController *viewController = [segue destinationViewController];
        viewController.operationType = @"changeType";
    } else if ([segue.identifier isEqualToString:@"deleteAndMoveType"]) {
        XXJOperateTypeTableViewController *viewController = [segue destinationViewController];
        viewController.operationType = @"deleteAndMoveType";
    }
}
@end
