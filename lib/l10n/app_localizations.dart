import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @btnLogin.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get btnLogin;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}'**
  String welcome(String name);

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'OPPERMANN VIETNAM CO., LTD.'**
  String get companyName;

  /// No description provided for @erpSystemName.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Resource Planning System'**
  String get erpSystemName;

  /// No description provided for @loginSystemHeader.
  ///
  /// In en, this message translates to:
  /// **'Login System'**
  String get loginSystemHeader;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to ERP System'**
  String get loginSubtitle;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Oppermann Vietnam'**
  String get copyright;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errorRequired;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get errorLoginFailed;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'A system error occurred'**
  String get errorGeneric;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'Human Resources'**
  String get hr;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @activePlans.
  ///
  /// In en, this message translates to:
  /// **'Active Plans'**
  String get activePlans;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get lowStock;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @successAdded.
  ///
  /// In en, this message translates to:
  /// **'Added successfully'**
  String get successAdded;

  /// No description provided for @successUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get successUpdated;

  /// No description provided for @successDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get successDeleted;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notice;

  /// No description provided for @featureUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'This feature is under development.\nPlease come back later.'**
  String get featureUnderDevelopment;

  /// No description provided for @pageContent.
  ///
  /// In en, this message translates to:
  /// **'Page Content: {path}'**
  String pageContent(String path);

  /// No description provided for @erpSystemShort.
  ///
  /// In en, this message translates to:
  /// **'ERP System'**
  String get erpSystemShort;

  /// No description provided for @oppermannHeader.
  ///
  /// In en, this message translates to:
  /// **'OPPERMANN'**
  String get oppermannHeader;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @productionOutput.
  ///
  /// In en, this message translates to:
  /// **'Production Output'**
  String get productionOutput;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @departmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get departmentTitle;

  /// No description provided for @deptName.
  ///
  /// In en, this message translates to:
  /// **'Department Name'**
  String get deptName;

  /// No description provided for @deptDesc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get deptDesc;

  /// No description provided for @searchDept.
  ///
  /// In en, this message translates to:
  /// **'Search Department...'**
  String get searchDept;

  /// No description provided for @addDept.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get addDept;

  /// No description provided for @editDept.
  ///
  /// In en, this message translates to:
  /// **'Edit Department'**
  String get editDept;

  /// No description provided for @deleteDept.
  ///
  /// In en, this message translates to:
  /// **'Delete Department'**
  String get deleteDept;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDelete(String name);

  /// No description provided for @warehouseTitle.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Management'**
  String get warehouseTitle;

  /// No description provided for @warehouseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage storage locations & inventory'**
  String get warehouseSubtitle;

  /// No description provided for @searchWarehouseHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or location...'**
  String get searchWarehouseHint;

  /// No description provided for @addWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Add Warehouse'**
  String get addWarehouse;

  /// No description provided for @editWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Edit Warehouse'**
  String get editWarehouse;

  /// No description provided for @deleteWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Delete Warehouse'**
  String get deleteWarehouse;

  /// No description provided for @confirmDeleteWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{name}\'? This action cannot be undone.'**
  String confirmDeleteWarehouse(String name);

  /// No description provided for @warehouseName.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Name'**
  String get warehouseName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @noWarehouseFound.
  ///
  /// In en, this message translates to:
  /// **'No warehouses found'**
  String get noWarehouseFound;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @cannotOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Cannot open maps'**
  String get cannotOpenMap;

  /// No description provided for @employeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeeTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @searchEmployee.
  ///
  /// In en, this message translates to:
  /// **'Search employee...'**
  String get searchEmployee;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @deleteEmployee.
  ///
  /// In en, this message translates to:
  /// **'Delete Employee'**
  String get deleteEmployee;

  /// No description provided for @confirmDeleteEmployee.
  ///
  /// In en, this message translates to:
  /// **'Delete employee {name}?'**
  String confirmDeleteEmployee(String name);

  /// No description provided for @selectDept.
  ///
  /// In en, this message translates to:
  /// **'Select Department'**
  String get selectDept;

  /// No description provided for @totalDepartments.
  ///
  /// In en, this message translates to:
  /// **'Total Departments'**
  String get totalDepartments;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @supplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get supplierTitle;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierName;

  /// No description provided for @searchSupplier.
  ///
  /// In en, this message translates to:
  /// **'Search supplier...'**
  String get searchSupplier;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get addSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get editSupplier;

  /// No description provided for @deleteSupplier.
  ///
  /// In en, this message translates to:
  /// **'Delete Supplier'**
  String get deleteSupplier;

  /// No description provided for @confirmDeleteSupplier.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteSupplier(String name);

  /// No description provided for @paymentTerm.
  ///
  /// In en, this message translates to:
  /// **'Payment Term'**
  String get paymentTerm;

  /// No description provided for @taxCode.
  ///
  /// In en, this message translates to:
  /// **'Tax Code'**
  String get taxCode;

  /// No description provided for @leadTime.
  ///
  /// In en, this message translates to:
  /// **'Lead Time'**
  String get leadTime;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get contactPerson;

  /// No description provided for @shortName.
  ///
  /// In en, this message translates to:
  /// **'Short Name'**
  String get shortName;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @originType.
  ///
  /// In en, this message translates to:
  /// **'Origin Type'**
  String get originType;

  /// No description provided for @isActiveProvider.
  ///
  /// In en, this message translates to:
  /// **'Is Active Provider?'**
  String get isActiveProvider;

  /// No description provided for @yarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Yarn Inventory'**
  String get yarnTitle;

  /// No description provided for @yarnName.
  ///
  /// In en, this message translates to:
  /// **'Yarn Name'**
  String get yarnName;

  /// No description provided for @itemCode.
  ///
  /// In en, this message translates to:
  /// **'Item Code'**
  String get itemCode;

  /// No description provided for @yarnType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get yarnType;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @searchYarn.
  ///
  /// In en, this message translates to:
  /// **'Search yarn (name, code)...'**
  String get searchYarn;

  /// No description provided for @addYarn.
  ///
  /// In en, this message translates to:
  /// **'Add Yarn'**
  String get addYarn;

  /// No description provided for @editYarn.
  ///
  /// In en, this message translates to:
  /// **'Edit Yarn'**
  String get editYarn;

  /// No description provided for @deleteYarn.
  ///
  /// In en, this message translates to:
  /// **'Delete Yarn'**
  String get deleteYarn;

  /// No description provided for @confirmDeleteYarn.
  ///
  /// In en, this message translates to:
  /// **'Delete yarn {name}?'**
  String confirmDeleteYarn(String name);

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get selectSupplier;

  /// No description provided for @noYarnFound.
  ///
  /// In en, this message translates to:
  /// **'No yarn items found'**
  String get noYarnFound;

  /// No description provided for @yarnLotTitle.
  ///
  /// In en, this message translates to:
  /// **'Yarn Lots'**
  String get yarnLotTitle;

  /// No description provided for @lotCode.
  ///
  /// In en, this message translates to:
  /// **'Lot Code'**
  String get lotCode;

  /// No description provided for @importDate.
  ///
  /// In en, this message translates to:
  /// **'Import Date'**
  String get importDate;

  /// No description provided for @totalKg.
  ///
  /// In en, this message translates to:
  /// **'Total (kg)'**
  String get totalKg;

  /// No description provided for @rollCount.
  ///
  /// In en, this message translates to:
  /// **'Rolls'**
  String get rollCount;

  /// No description provided for @warehouseLoc.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get warehouseLoc;

  /// No description provided for @containerCode.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get containerCode;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @searchYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Search lot code...'**
  String get searchYarnLot;

  /// No description provided for @addYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Add Yarn Lot'**
  String get addYarnLot;

  /// No description provided for @editYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Edit Yarn Lot'**
  String get editYarnLot;

  /// No description provided for @deleteYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Delete Yarn Lot'**
  String get deleteYarnLot;

  /// No description provided for @confirmDeleteYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Delete yarn lot {code}?'**
  String confirmDeleteYarnLot(String code);

  /// No description provided for @selectYarn.
  ///
  /// In en, this message translates to:
  /// **'Select Yarn'**
  String get selectYarn;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectEmployee;

  /// No description provided for @materialTitle.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialTitle;

  /// No description provided for @materialMaster.
  ///
  /// In en, this message translates to:
  /// **'Materials Master'**
  String get materialMaster;

  /// No description provided for @materialBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Inventory > Materials'**
  String get materialBreadcrumb;

  /// No description provided for @materialName.
  ///
  /// In en, this message translates to:
  /// **'Material Name'**
  String get materialName;

  /// No description provided for @materialCode.
  ///
  /// In en, this message translates to:
  /// **'Material Code'**
  String get materialCode;

  /// No description provided for @materialType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get materialType;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @importedBy.
  ///
  /// In en, this message translates to:
  /// **'Imported By'**
  String get importedBy;

  /// No description provided for @searchMaterial.
  ///
  /// In en, this message translates to:
  /// **'Search material...'**
  String get searchMaterial;

  /// No description provided for @searchMaterialHint.
  ///
  /// In en, this message translates to:
  /// **'Search Code, Name...'**
  String get searchMaterialHint;

  /// No description provided for @totalMaterials.
  ///
  /// In en, this message translates to:
  /// **'Total Materials'**
  String get totalMaterials;

  /// No description provided for @addMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterial;

  /// No description provided for @editMaterial.
  ///
  /// In en, this message translates to:
  /// **'Edit Material'**
  String get editMaterial;

  /// No description provided for @deleteMaterial.
  ///
  /// In en, this message translates to:
  /// **'Delete Material'**
  String get deleteMaterial;

  /// No description provided for @confirmDeleteMaterial.
  ///
  /// In en, this message translates to:
  /// **'Delete material {name}?'**
  String confirmDeleteMaterial(String name);

  /// No description provided for @noMaterialFound.
  ///
  /// In en, this message translates to:
  /// **'No materials found'**
  String get noMaterialFound;

  /// No description provided for @selectImporter.
  ///
  /// In en, this message translates to:
  /// **'Select Importer'**
  String get selectImporter;

  /// No description provided for @selectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select Unit'**
  String get selectUnit;

  /// No description provided for @hsCode.
  ///
  /// In en, this message translates to:
  /// **'HS Code'**
  String get hsCode;

  /// No description provided for @denier.
  ///
  /// In en, this message translates to:
  /// **'Denier'**
  String get denier;

  /// No description provided for @denierHint.
  ///
  /// In en, this message translates to:
  /// **'Denier (e.g 1000D)'**
  String get denierHint;

  /// No description provided for @filament.
  ///
  /// In en, this message translates to:
  /// **'Filament'**
  String get filament;

  /// No description provided for @minStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get minStock;

  /// No description provided for @uomBasePurchase.
  ///
  /// In en, this message translates to:
  /// **'UOM Purchase (Base)'**
  String get uomBasePurchase;

  /// No description provided for @uomProduction.
  ///
  /// In en, this message translates to:
  /// **'UOM Production'**
  String get uomProduction;

  /// No description provided for @uomBP.
  ///
  /// In en, this message translates to:
  /// **'UOM (B/P)'**
  String get uomBP;

  /// No description provided for @specs.
  ///
  /// In en, this message translates to:
  /// **'Specs'**
  String get specs;

  /// No description provided for @unitTitle.
  ///
  /// In en, this message translates to:
  /// **'Units of Measurement'**
  String get unitTitle;

  /// No description provided for @unitName.
  ///
  /// In en, this message translates to:
  /// **'Unit Name'**
  String get unitName;

  /// No description provided for @searchUnit.
  ///
  /// In en, this message translates to:
  /// **'Search unit...'**
  String get searchUnit;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get addUnit;

  /// No description provided for @editUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit'**
  String get editUnit;

  /// No description provided for @deleteUnit.
  ///
  /// In en, this message translates to:
  /// **'Delete Unit'**
  String get deleteUnit;

  /// No description provided for @confirmDeleteUnit.
  ///
  /// In en, this message translates to:
  /// **'Delete unit {name}?'**
  String confirmDeleteUnit(String name);

  /// No description provided for @noUnitFound.
  ///
  /// In en, this message translates to:
  /// **'No units found'**
  String get noUnitFound;

  /// No description provided for @machineTitle.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get machineTitle;

  /// No description provided for @machineName.
  ///
  /// In en, this message translates to:
  /// **'Machine Name'**
  String get machineName;

  /// No description provided for @totalLines.
  ///
  /// In en, this message translates to:
  /// **'Total Lines'**
  String get totalLines;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @searchMachine.
  ///
  /// In en, this message translates to:
  /// **'Search machine...'**
  String get searchMachine;

  /// No description provided for @addMachine.
  ///
  /// In en, this message translates to:
  /// **'Add Machine'**
  String get addMachine;

  /// No description provided for @editMachine.
  ///
  /// In en, this message translates to:
  /// **'Edit Machine'**
  String get editMachine;

  /// No description provided for @deleteMachine.
  ///
  /// In en, this message translates to:
  /// **'Delete Machine'**
  String get deleteMachine;

  /// No description provided for @confirmDeleteMachine.
  ///
  /// In en, this message translates to:
  /// **'Delete machine {name}?'**
  String confirmDeleteMachine(String name);

  /// No description provided for @noMachineFound.
  ///
  /// In en, this message translates to:
  /// **'No machines found'**
  String get noMachineFound;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @spinning.
  ///
  /// In en, this message translates to:
  /// **'Spinning'**
  String get spinning;

  /// No description provided for @yarnOut.
  ///
  /// In en, this message translates to:
  /// **'Yarn Out'**
  String get yarnOut;

  /// No description provided for @unassignedArea.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Area'**
  String get unassignedArea;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusSpinning.
  ///
  /// In en, this message translates to:
  /// **'Spinning'**
  String get statusSpinning;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get statusMaintenance;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @machineHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History: {name}'**
  String machineHistoryTitle(String name);

  /// No description provided for @noHistoryData.
  ///
  /// In en, this message translates to:
  /// **'No activity history available.'**
  String get noHistoryData;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @durationFormatMin.
  ///
  /// In en, this message translates to:
  /// **'{min} min'**
  String durationFormatMin(String min);

  /// No description provided for @durationFormatHour.
  ///
  /// In en, this message translates to:
  /// **'{hour}h {min}m'**
  String durationFormatHour(int hour, int min);

  /// No description provided for @timeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timeCurrent;

  /// No description provided for @changeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Status: {status}'**
  String changeStatusTitle(String status);

  /// No description provided for @confirmStatusChangeMsg.
  ///
  /// In en, this message translates to:
  /// **'Do you want to change machine {name} to {status}?'**
  String confirmStatusChangeMsg(String name, String status);

  /// No description provided for @reasonIssue.
  ///
  /// In en, this message translates to:
  /// **'Reason / Issue Description'**
  String get reasonIssue;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason (e.g. Broken thread, Motor failure...)'**
  String get enterReason;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason'**
  String get reasonRequired;

  /// No description provided for @captureEvidence.
  ///
  /// In en, this message translates to:
  /// **'Capture Evidence'**
  String get captureEvidence;

  /// No description provided for @openingCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening Camera...'**
  String get openingCamera;

  /// No description provided for @cameraFeatureDev.
  ///
  /// In en, this message translates to:
  /// **'Camera feature is under development'**
  String get cameraFeatureDev;

  /// No description provided for @shiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Shifts'**
  String get shiftTitle;

  /// No description provided for @shiftName.
  ///
  /// In en, this message translates to:
  /// **'Shift Name'**
  String get shiftName;

  /// No description provided for @searchShift.
  ///
  /// In en, this message translates to:
  /// **'Search shift...'**
  String get searchShift;

  /// No description provided for @addShift.
  ///
  /// In en, this message translates to:
  /// **'Add Shift'**
  String get addShift;

  /// No description provided for @editShift.
  ///
  /// In en, this message translates to:
  /// **'Edit Shift'**
  String get editShift;

  /// No description provided for @deleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete Shift'**
  String get deleteShift;

  /// No description provided for @confirmDeleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete shift {name}?'**
  String confirmDeleteShift(String name);

  /// No description provided for @noShiftFound.
  ///
  /// In en, this message translates to:
  /// **'No shifts found'**
  String get noShiftFound;

  /// No description provided for @basketTitle.
  ///
  /// In en, this message translates to:
  /// **'Baskets'**
  String get basketTitle;

  /// No description provided for @basketCode.
  ///
  /// In en, this message translates to:
  /// **'Basket Code'**
  String get basketCode;

  /// No description provided for @basketTitleVS2.
  ///
  /// In en, this message translates to:
  /// **'Basket'**
  String get basketTitleVS2;

  /// No description provided for @basketBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Inventory > Baskets'**
  String get basketBreadcrumb;

  /// No description provided for @totalBaskets.
  ///
  /// In en, this message translates to:
  /// **'Total Baskets'**
  String get totalBaskets;

  /// No description provided for @tareWeight.
  ///
  /// In en, this message translates to:
  /// **'Tare Weight (kg)'**
  String get tareWeight;

  /// No description provided for @searchBasket.
  ///
  /// In en, this message translates to:
  /// **'Search basket...'**
  String get searchBasket;

  /// No description provided for @addBasket.
  ///
  /// In en, this message translates to:
  /// **'Add Basket'**
  String get addBasket;

  /// No description provided for @editBasket.
  ///
  /// In en, this message translates to:
  /// **'Edit Basket'**
  String get editBasket;

  /// No description provided for @deleteBasket.
  ///
  /// In en, this message translates to:
  /// **'Delete Basket'**
  String get deleteBasket;

  /// No description provided for @confirmDeleteBasket.
  ///
  /// In en, this message translates to:
  /// **'Delete basket {code}?'**
  String confirmDeleteBasket(String code);

  /// No description provided for @noBasketFound.
  ///
  /// In en, this message translates to:
  /// **'No baskets found'**
  String get noBasketFound;

  /// No description provided for @basketFound.
  ///
  /// In en, this message translates to:
  /// **'Basket Found: {code}'**
  String basketFound(String code);

  /// No description provided for @basketNotFoundOrNotReady.
  ///
  /// In en, this message translates to:
  /// **'Basket not found or NOT READY'**
  String get basketNotFoundOrNotReady;

  /// No description provided for @stReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get stReady;

  /// No description provided for @stInUse.
  ///
  /// In en, this message translates to:
  /// **'In Use'**
  String get stInUse;

  /// No description provided for @stHolding.
  ///
  /// In en, this message translates to:
  /// **'Holding'**
  String get stHolding;

  /// No description provided for @stDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get stDamaged;

  /// No description provided for @errorTareWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Tare weight must be greater than 0'**
  String get errorTareWeightInvalid;

  /// No description provided for @dyeColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Dye Colors'**
  String get dyeColorTitle;

  /// No description provided for @colorName.
  ///
  /// In en, this message translates to:
  /// **'Color Name'**
  String get colorName;

  /// No description provided for @hexCode.
  ///
  /// In en, this message translates to:
  /// **'Hex Code'**
  String get hexCode;

  /// No description provided for @searchColor.
  ///
  /// In en, this message translates to:
  /// **'Search color...'**
  String get searchColor;

  /// No description provided for @addColor.
  ///
  /// In en, this message translates to:
  /// **'Add Color'**
  String get addColor;

  /// No description provided for @editColor.
  ///
  /// In en, this message translates to:
  /// **'Edit Color'**
  String get editColor;

  /// No description provided for @deleteColor.
  ///
  /// In en, this message translates to:
  /// **'Delete Color'**
  String get deleteColor;

  /// No description provided for @confirmDeleteColor.
  ///
  /// In en, this message translates to:
  /// **'Delete color {name}?'**
  String confirmDeleteColor(String name);

  /// No description provided for @noColorFound.
  ///
  /// In en, this message translates to:
  /// **'No colors found'**
  String get noColorFound;

  /// No description provided for @invalidHex.
  ///
  /// In en, this message translates to:
  /// **'Invalid Hex Code (e.g., #FF0000)'**
  String get invalidHex;

  /// No description provided for @productTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productTitle;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get productImage;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product...'**
  String get searchProduct;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete product {code}?'**
  String confirmDeleteProduct(String code);

  /// No description provided for @noProductFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductFound;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @standardTitle.
  ///
  /// In en, this message translates to:
  /// **'Standards'**
  String get standardTitle;

  /// No description provided for @standardCode.
  ///
  /// In en, this message translates to:
  /// **'Standard Code'**
  String get standardCode;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @dyeColor.
  ///
  /// In en, this message translates to:
  /// **'Dye Color'**
  String get dyeColor;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width (mm)'**
  String get width;

  /// No description provided for @thickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness (mm)'**
  String get thickness;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength (daN)'**
  String get strength;

  /// No description provided for @elongation.
  ///
  /// In en, this message translates to:
  /// **'Elongation (%)'**
  String get elongation;

  /// No description provided for @colorFastDry.
  ///
  /// In en, this message translates to:
  /// **'Color Fastness (Dry)'**
  String get colorFastDry;

  /// No description provided for @colorFastWet.
  ///
  /// In en, this message translates to:
  /// **'Color Fastness (Wet)'**
  String get colorFastWet;

  /// No description provided for @deltaE.
  ///
  /// In en, this message translates to:
  /// **'Delta E'**
  String get deltaE;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @weftDensity.
  ///
  /// In en, this message translates to:
  /// **'Weft Density (pick/10cm)'**
  String get weftDensity;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (g/m)'**
  String get weight;

  /// No description provided for @searchStandard.
  ///
  /// In en, this message translates to:
  /// **'Search standard...'**
  String get searchStandard;

  /// No description provided for @addStandard.
  ///
  /// In en, this message translates to:
  /// **'Add Standard'**
  String get addStandard;

  /// No description provided for @editStandard.
  ///
  /// In en, this message translates to:
  /// **'Edit Standard'**
  String get editStandard;

  /// No description provided for @deleteStandard.
  ///
  /// In en, this message translates to:
  /// **'Delete Standard'**
  String get deleteStandard;

  /// No description provided for @confirmDeleteStandard.
  ///
  /// In en, this message translates to:
  /// **'Delete standard {code}?'**
  String confirmDeleteStandard(String code);

  /// No description provided for @noStandardFound.
  ///
  /// In en, this message translates to:
  /// **'No standards found'**
  String get noStandardFound;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Schedules'**
  String get scheduleTitle;

  /// No description provided for @workDate.
  ///
  /// In en, this message translates to:
  /// **'Work Date'**
  String get workDate;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @searchSchedule.
  ///
  /// In en, this message translates to:
  /// **'Search schedule...'**
  String get searchSchedule;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Assign Schedule'**
  String get addSchedule;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editSchedule;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete Schedule'**
  String get deleteSchedule;

  /// No description provided for @confirmDeleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule for {name} on {date}?'**
  String confirmDeleteSchedule(String name, String date);

  /// No description provided for @noScheduleFound.
  ///
  /// In en, this message translates to:
  /// **'No schedules found'**
  String get noScheduleFound;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterDate;

  /// No description provided for @errorDuplicateSchedule.
  ///
  /// In en, this message translates to:
  /// **'Conflict: This employee already has a shift on this date.'**
  String get errorDuplicateSchedule;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errorUnknown;

  /// No description provided for @weavingTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Weaving Tickets'**
  String get weavingTicketTitle;

  /// No description provided for @ticketCode.
  ///
  /// In en, this message translates to:
  /// **'Ticket Code'**
  String get ticketCode;

  /// No description provided for @loadDate.
  ///
  /// In en, this message translates to:
  /// **'Load date'**
  String get loadDate;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @timeIn.
  ///
  /// In en, this message translates to:
  /// **'Time In'**
  String get timeIn;

  /// No description provided for @empIn.
  ///
  /// In en, this message translates to:
  /// **'Emp In'**
  String get empIn;

  /// No description provided for @timeOut.
  ///
  /// In en, this message translates to:
  /// **'Time Out'**
  String get timeOut;

  /// No description provided for @empOut.
  ///
  /// In en, this message translates to:
  /// **'Emp Out'**
  String get empOut;

  /// No description provided for @tage.
  ///
  /// In en, this message translates to:
  /// **'Tage weight'**
  String get tage;

  /// No description provided for @machineInfo.
  ///
  /// In en, this message translates to:
  /// **'Machine / Line'**
  String get machineInfo;

  /// No description provided for @yarnInfo.
  ///
  /// In en, this message translates to:
  /// **'Yarn Lot / Date'**
  String get yarnInfo;

  /// No description provided for @standardData.
  ///
  /// In en, this message translates to:
  /// **'Standard Specifications'**
  String get standardData;

  /// No description provided for @weightInfo.
  ///
  /// In en, this message translates to:
  /// **'Gross / Net / Tare'**
  String get weightInfo;

  /// No description provided for @lengthKnots.
  ///
  /// In en, this message translates to:
  /// **'Length (m) / Knots'**
  String get lengthKnots;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get employees;

  /// No description provided for @timeInOut.
  ///
  /// In en, this message translates to:
  /// **'Time In / Out'**
  String get timeInOut;

  /// No description provided for @inspections.
  ///
  /// In en, this message translates to:
  /// **'QC Inspections'**
  String get inspections;

  /// No description provided for @addTicket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get addTicket;

  /// No description provided for @stageName.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stageName;

  /// No description provided for @gross.
  ///
  /// In en, this message translates to:
  /// **'Gross Weight'**
  String get gross;

  /// No description provided for @density.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get density;

  /// No description provided for @tension.
  ///
  /// In en, this message translates to:
  /// **'Tension'**
  String get tension;

  /// No description provided for @bowing.
  ///
  /// In en, this message translates to:
  /// **'Bowing'**
  String get bowing;

  /// No description provided for @inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspector;

  /// No description provided for @noTicketSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a ticket to view details'**
  String get noTicketSelected;

  /// No description provided for @deleteTicket.
  ///
  /// In en, this message translates to:
  /// **'Delete Ticket'**
  String get deleteTicket;

  /// No description provided for @confirmDeleteTicket.
  ///
  /// In en, this message translates to:
  /// **'Delete ticket {code}?'**
  String confirmDeleteTicket(String code);

  /// No description provided for @deleteInspection.
  ///
  /// In en, this message translates to:
  /// **'Delete Inspection'**
  String get deleteInspection;

  /// No description provided for @machineAndMaterial.
  ///
  /// In en, this message translates to:
  /// **'Machine & Material'**
  String get machineAndMaterial;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'General Info'**
  String get generalInfo;

  /// No description provided for @personnel.
  ///
  /// In en, this message translates to:
  /// **'Personnel'**
  String get personnel;

  /// No description provided for @resultsUpdateOnly.
  ///
  /// In en, this message translates to:
  /// **'Results (Update Only)'**
  String get resultsUpdateOnly;

  /// No description provided for @machineOperation.
  ///
  /// In en, this message translates to:
  /// **'Machine Operation'**
  String get machineOperation;

  /// No description provided for @selectProductBefore.
  ///
  /// In en, this message translates to:
  /// **'Select the product first'**
  String get selectProductBefore;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @assignBasket.
  ///
  /// In en, this message translates to:
  /// **'Assign Basket'**
  String get assignBasket;

  /// No description provided for @selectBasket.
  ///
  /// In en, this message translates to:
  /// **'Select Ready Basket'**
  String get selectBasket;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode / Input Code'**
  String get scanBarcode;

  /// No description provided for @scanBarcodeSubline.
  ///
  /// In en, this message translates to:
  /// **'Scan the basket code here to select your own items'**
  String get scanBarcodeSubline;

  /// No description provided for @addInspection.
  ///
  /// In en, this message translates to:
  /// **'Add QC'**
  String get addInspection;

  /// No description provided for @viewTicket.
  ///
  /// In en, this message translates to:
  /// **'View Ticket'**
  String get viewTicket;

  /// No description provided for @editTicket.
  ///
  /// In en, this message translates to:
  /// **'Edit ticket'**
  String get editTicket;

  /// No description provided for @currentBasket.
  ///
  /// In en, this message translates to:
  /// **'Current Basket'**
  String get currentBasket;

  /// No description provided for @noActiveBasket.
  ///
  /// In en, this message translates to:
  /// **'No active basket'**
  String get noActiveBasket;

  /// No description provided for @confirmRelease.
  ///
  /// In en, this message translates to:
  /// **'Finish this ticket and release basket?'**
  String get confirmRelease;

  /// No description provided for @basketAssigned.
  ///
  /// In en, this message translates to:
  /// **'Basket assigned successfully'**
  String get basketAssigned;

  /// No description provided for @releaseBasket.
  ///
  /// In en, this message translates to:
  /// **'Release Basket / Finish Ticket'**
  String get releaseBasket;

  /// No description provided for @finishTicket.
  ///
  /// In en, this message translates to:
  /// **'Finish Ticket'**
  String get finishTicket;

  /// No description provided for @grossWeight.
  ///
  /// In en, this message translates to:
  /// **'Gross Weight (kg)'**
  String get grossWeight;

  /// No description provided for @netWeight.
  ///
  /// In en, this message translates to:
  /// **'Net Weight (kg)'**
  String get netWeight;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length (m)'**
  String get length;

  /// No description provided for @splice.
  ///
  /// In en, this message translates to:
  /// **'Splice'**
  String get splice;

  /// No description provided for @bow.
  ///
  /// In en, this message translates to:
  /// **'Bow'**
  String get bow;

  /// No description provided for @employeeOut.
  ///
  /// In en, this message translates to:
  /// **'Receiver / Operator Out'**
  String get employeeOut;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'Ticket Details'**
  String get ticketDetails;

  /// No description provided for @inspectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Inspection History'**
  String get inspectionHistory;

  /// No description provided for @newInspection.
  ///
  /// In en, this message translates to:
  /// **'New Inspection'**
  String get newInspection;

  /// No description provided for @confirmReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Finish'**
  String get confirmReleaseTitle;

  /// No description provided for @confirmReleaseMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish this ticket and release the basket?'**
  String get confirmReleaseMsg;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// No description provided for @noTicketsFoundForThisDate.
  ///
  /// In en, this message translates to:
  /// **'No tickets found for this date'**
  String get noTicketsFoundForThisDate;

  /// No description provided for @noBasket.
  ///
  /// In en, this message translates to:
  /// **'No Basket'**
  String get noBasket;

  /// No description provided for @productionInfo.
  ///
  /// In en, this message translates to:
  /// **'Production Info'**
  String get productionInfo;

  /// No description provided for @timeAndPersonnel.
  ///
  /// In en, this message translates to:
  /// **'Time & Personnel'**
  String get timeAndPersonnel;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @noInspectionsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No inspections recorded'**
  String get noInspectionsRecorded;

  /// No description provided for @inspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get inspection;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @userManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagementTitle;

  /// No description provided for @searchUser.
  ///
  /// In en, this message translates to:
  /// **'Search users (name, email)...'**
  String get searchUser;

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUserFound;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last Login'**
  String get lastLogin;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not Linked'**
  String get notLinked;

  /// No description provided for @superuser.
  ///
  /// In en, this message translates to:
  /// **'SUPERUSER'**
  String get superuser;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @linkToEmployee.
  ///
  /// In en, this message translates to:
  /// **'Link to Employee'**
  String get linkToEmployee;

  /// No description provided for @linkEmployeeHelper.
  ///
  /// In en, this message translates to:
  /// **'Select an employee to link with this account'**
  String get linkEmployeeHelper;

  /// No description provided for @noEmployeeLinkedOption.
  ///
  /// In en, this message translates to:
  /// **'--- No Employee Linked ---'**
  String get noEmployeeLinkedOption;

  /// No description provided for @passwordRequiredNew.
  ///
  /// In en, this message translates to:
  /// **'Required for new user'**
  String get passwordRequiredNew;

  /// No description provided for @newPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'New Password (Leave blank to keep)'**
  String get newPasswordPlaceholder;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @isActiveSwitch.
  ///
  /// In en, this message translates to:
  /// **'Is Active'**
  String get isActiveSwitch;

  /// No description provided for @isSuperuserSwitch.
  ///
  /// In en, this message translates to:
  /// **'Is Superuser'**
  String get isSuperuserSwitch;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteUserMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteUserMsg(String name);

  /// No description provided for @prodStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Production Statistics'**
  String get prodStatsTitle;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// No description provided for @recalculateToday.
  ///
  /// In en, this message translates to:
  /// **'Recalculate (Today)'**
  String get recalculateToday;

  /// No description provided for @searchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search product code, note...'**
  String get searchProductHint;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get filterYesterday;

  /// No description provided for @filter7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get filter7Days;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get filterThisMonth;

  /// No description provided for @filterLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get filterLastMonth;

  /// No description provided for @filterThisQuarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get filterThisQuarter;

  /// No description provided for @filterThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get filterThisYear;

  /// No description provided for @filterCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Date'**
  String get filterCustom;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @totalProduction.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PRODUCTION'**
  String get totalProduction;

  /// No description provided for @totalLength.
  ///
  /// In en, this message translates to:
  /// **'TOTAL LENGTH'**
  String get totalLength;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get itemCount;

  /// No description provided for @noStatsData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noStatsData;

  /// No description provided for @machines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get machines;

  /// No description provided for @copySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get copySuccess;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Creating Excel file...'**
  String get exporting;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// No description provided for @purchaseOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Orders'**
  String get purchaseOrderTitle;

  /// No description provided for @purchaseOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage procurement and suppliers'**
  String get purchaseOrderSubtitle;

  /// No description provided for @createPO.
  ///
  /// In en, this message translates to:
  /// **'CREATE PO'**
  String get createPO;

  /// No description provided for @searchPO.
  ///
  /// In en, this message translates to:
  /// **'Search PO Number...'**
  String get searchPO;

  /// No description provided for @poNumber.
  ///
  /// In en, this message translates to:
  /// **'PO Number'**
  String get poNumber;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'Expected Arrival (ETA)'**
  String get eta;

  /// No description provided for @incoterm.
  ///
  /// In en, this message translates to:
  /// **'Incoterm'**
  String get incoterm;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRate;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @poDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Order Detail'**
  String get poDetailTitle;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @noItemsPO.
  ///
  /// In en, this message translates to:
  /// **'No items in this order yet.'**
  String get noItemsPO;

  /// No description provided for @addMaterialPrompt.
  ///
  /// In en, this message translates to:
  /// **'Click \'+ Add Material\' to start.'**
  String get addMaterialPrompt;

  /// No description provided for @materialInfo.
  ///
  /// In en, this message translates to:
  /// **'MATERIAL INFORMATION'**
  String get materialInfo;

  /// No description provided for @tapToSearch.
  ///
  /// In en, this message translates to:
  /// **'Tap to search material...'**
  String get tapToSearch;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION DETAILS'**
  String get transactionDetails;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line Total'**
  String get lineTotal;

  /// No description provided for @estimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated Total'**
  String get estimatedTotal;

  /// No description provided for @confirmAdd.
  ///
  /// In en, this message translates to:
  /// **'Confirm Add'**
  String get confirmAdd;

  /// No description provided for @searchMaterialPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type name, code, specs...'**
  String get searchMaterialPlaceholder;

  /// No description provided for @deletePO.
  ///
  /// In en, this message translates to:
  /// **'Delete PO'**
  String get deletePO;

  /// No description provided for @confirmDeletePO.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete PO {number}?'**
  String confirmDeletePO(String number);

  /// No description provided for @bomTitle.
  ///
  /// In en, this message translates to:
  /// **'BOM Management'**
  String get bomTitle;

  /// No description provided for @bomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Production > Bill of Materials'**
  String get bomSubtitle;

  /// No description provided for @addBOM.
  ///
  /// In en, this message translates to:
  /// **'ADD BOM'**
  String get addBOM;

  /// No description provided for @noBOMFound.
  ///
  /// In en, this message translates to:
  /// **'No BOM configurations found'**
  String get noBOMFound;

  /// No description provided for @bomCode.
  ///
  /// In en, this message translates to:
  /// **'BOM Code'**
  String get bomCode;

  /// No description provided for @bomName.
  ///
  /// In en, this message translates to:
  /// **'BOM Name'**
  String get bomName;

  /// No description provided for @baseQty.
  ///
  /// In en, this message translates to:
  /// **'Base Qty'**
  String get baseQty;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @viewIngredients.
  ///
  /// In en, this message translates to:
  /// **'View Ingredients'**
  String get viewIngredients;

  /// No description provided for @newBOM.
  ///
  /// In en, this message translates to:
  /// **'New BOM'**
  String get newBOM;

  /// No description provided for @editBOM.
  ///
  /// In en, this message translates to:
  /// **'Edit BOM Header'**
  String get editBOM;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @chooseProduct.
  ///
  /// In en, this message translates to:
  /// **'Choose a product'**
  String get chooseProduct;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @setActiveVersion.
  ///
  /// In en, this message translates to:
  /// **'Set as Active Version'**
  String get setActiveVersion;

  /// No description provided for @bomCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'BOM Code is required'**
  String get bomCodeRequired;

  /// No description provided for @productRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a Product!'**
  String get productRequired;

  /// No description provided for @deleteBOM.
  ///
  /// In en, this message translates to:
  /// **'Delete BOM'**
  String get deleteBOM;

  /// No description provided for @confirmDeleteBOM.
  ///
  /// In en, this message translates to:
  /// **'Delete BOM {code}? This will remove all material details.'**
  String confirmDeleteBOM(String code);

  /// No description provided for @bomIngredientsConfig.
  ///
  /// In en, this message translates to:
  /// **'BOM Ingredients Config'**
  String get bomIngredientsConfig;

  /// No description provided for @matId.
  ///
  /// In en, this message translates to:
  /// **'Mat ID'**
  String get matId;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @stdQty.
  ///
  /// In en, this message translates to:
  /// **'Std'**
  String get stdQty;

  /// No description provided for @wastage.
  ///
  /// In en, this message translates to:
  /// **'Waste'**
  String get wastage;

  /// No description provided for @grossQty.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get grossQty;

  /// No description provided for @saveDetail.
  ///
  /// In en, this message translates to:
  /// **'Save Detail'**
  String get saveDetail;

  /// No description provided for @editMaterialDetail.
  ///
  /// In en, this message translates to:
  /// **'Edit Material Detail'**
  String get editMaterialDetail;

  /// No description provided for @importDeclarationTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Declarations'**
  String get importDeclarationTitle;

  /// No description provided for @importDeclarationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage customs declarations (E31, A11...)'**
  String get importDeclarationSubtitle;

  /// No description provided for @newDeclaration.
  ///
  /// In en, this message translates to:
  /// **'NEW DECLARATION'**
  String get newDeclaration;

  /// No description provided for @searchDeclarationHint.
  ///
  /// In en, this message translates to:
  /// **'Search No, Invoice, B/L...'**
  String get searchDeclarationHint;

  /// No description provided for @noDeclarationFound.
  ///
  /// In en, this message translates to:
  /// **'No declarations found'**
  String get noDeclarationFound;

  /// No description provided for @declarationNo.
  ///
  /// In en, this message translates to:
  /// **'Declaration No'**
  String get declarationNo;

  /// No description provided for @declarationDate.
  ///
  /// In en, this message translates to:
  /// **'Declaration Date'**
  String get declarationDate;

  /// No description provided for @declarationType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get declarationType;

  /// No description provided for @invoiceBill.
  ///
  /// In en, this message translates to:
  /// **'Invoice / Bill'**
  String get invoiceBill;

  /// No description provided for @totalTax.
  ///
  /// In en, this message translates to:
  /// **'Total Tax'**
  String get totalTax;

  /// No description provided for @invoiceAbbr.
  ///
  /// In en, this message translates to:
  /// **'Inv'**
  String get invoiceAbbr;

  /// No description provided for @billOfLadingAbbr.
  ///
  /// In en, this message translates to:
  /// **'B/L'**
  String get billOfLadingAbbr;

  /// No description provided for @invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice No'**
  String get invoiceNo;

  /// No description provided for @billOfLading.
  ///
  /// In en, this message translates to:
  /// **'Bill of Lading'**
  String get billOfLading;

  /// No description provided for @createDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Create Declaration'**
  String get createDeclaration;

  /// No description provided for @editDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Edit Declaration'**
  String get editDeclaration;

  /// No description provided for @totalTaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Tax Amount'**
  String get totalTaxAmount;

  /// No description provided for @deleteDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Delete Declaration'**
  String get deleteDeclaration;

  /// No description provided for @confirmDeleteDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete declaration {number}?'**
  String confirmDeleteDeclaration(String number);

  /// No description provided for @declarationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Declaration Details'**
  String get declarationDetailTitle;

  /// No description provided for @declarationItemsList.
  ///
  /// In en, this message translates to:
  /// **'Cargo List'**
  String get declarationItemsList;

  /// No description provided for @addDeclarationItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addDeclarationItem;

  /// No description provided for @noDeclarationItems.
  ///
  /// In en, this message translates to:
  /// **'No items in this declaration.'**
  String get noDeclarationItems;

  /// No description provided for @addDeclarationItemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Click \'+ Add Item\' to start.'**
  String get addDeclarationItemPrompt;

  /// No description provided for @editDeclarationItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editDeclarationItem;

  /// No description provided for @addDeclarationItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item to Declaration'**
  String get addDeclarationItemTitle;

  /// No description provided for @materialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get materialLabel;

  /// No description provided for @selectMaterialPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select material...'**
  String get selectMaterialPlaceholder;

  /// No description provided for @actualHSCode.
  ///
  /// In en, this message translates to:
  /// **'HS Code (Actual)'**
  String get actualHSCode;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPriceLabel;

  /// No description provided for @errorSelectMaterial.
  ///
  /// In en, this message translates to:
  /// **'Please select a material!'**
  String get errorSelectMaterial;

  /// No description provided for @searchMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Material'**
  String get searchMaterialTitle;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItemTitle;

  /// No description provided for @confirmDeleteItemMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDeleteItemMsg;

  /// No description provided for @registrationDate.
  ///
  /// In en, this message translates to:
  /// **'Reg. Date'**
  String get registrationDate;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @stockInTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock In'**
  String get stockInTitle;

  /// No description provided for @stockInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage stock in receipts'**
  String get stockInSubtitle;

  /// No description provided for @tabMaterial.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get tabMaterial;

  /// No description provided for @tabSemiFinished.
  ///
  /// In en, this message translates to:
  /// **'Semi-finished'**
  String get tabSemiFinished;

  /// No description provided for @tabFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished Goods'**
  String get tabFinished;

  /// No description provided for @goodsList.
  ///
  /// In en, this message translates to:
  /// **'Goods List'**
  String get goodsList;

  /// No description provided for @addRow.
  ///
  /// In en, this message translates to:
  /// **'Add Row'**
  String get addRow;

  /// No description provided for @saveReceipt.
  ///
  /// In en, this message translates to:
  /// **'SAVE RECEIPT'**
  String get saveReceipt;

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt No'**
  String get receiptNumber;

  /// No description provided for @receivingWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Receiving Warehouse'**
  String get receivingWarehouse;

  /// No description provided for @sendingDepartment.
  ///
  /// In en, this message translates to:
  /// **'Sending Dept'**
  String get sendingDepartment;

  /// No description provided for @semiFinishedCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get semiFinishedCode;

  /// No description provided for @semiFinishedName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get semiFinishedName;

  /// No description provided for @goodQty.
  ///
  /// In en, this message translates to:
  /// **'Good Qty'**
  String get goodQty;

  /// No description provided for @badQty.
  ///
  /// In en, this message translates to:
  /// **'Bad Qty'**
  String get badQty;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @carton.
  ///
  /// In en, this message translates to:
  /// **'Carton/Bundle'**
  String get carton;

  /// No description provided for @selectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get selectPlaceholder;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @generalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'General Info - {title}'**
  String generalInfoTitle(String title);

  /// No description provided for @createReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Receipt'**
  String get createReceiptTitle;

  /// No description provided for @editReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt Details'**
  String get editReceiptTitle;

  /// No description provided for @logisticsInfo.
  ///
  /// In en, this message translates to:
  /// **'Logistics Info'**
  String get logisticsInfo;

  /// No description provided for @byPO.
  ///
  /// In en, this message translates to:
  /// **'By Purchase Order (PO)'**
  String get byPO;

  /// No description provided for @customsDeclarationOptional.
  ///
  /// In en, this message translates to:
  /// **'Customs Declaration (Optional)'**
  String get customsDeclarationOptional;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'--- No Selection ---'**
  String get noSelection;

  /// No description provided for @loadingDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Loading declarations...'**
  String get loadingDeclaration;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get createdBy;

  /// No description provided for @containerNumber.
  ///
  /// In en, this message translates to:
  /// **'Container No'**
  String get containerNumber;

  /// No description provided for @sealNumber.
  ///
  /// In en, this message translates to:
  /// **'Seal No'**
  String get sealNumber;

  /// No description provided for @poQtyKg.
  ///
  /// In en, this message translates to:
  /// **'PO Qty (Kg)'**
  String get poQtyKg;

  /// No description provided for @poQtyCones.
  ///
  /// In en, this message translates to:
  /// **'PO Qty (Cones)'**
  String get poQtyCones;

  /// No description provided for @actualQtyKg.
  ///
  /// In en, this message translates to:
  /// **'Actual (Kg)'**
  String get actualQtyKg;

  /// No description provided for @actualQtyCones.
  ///
  /// In en, this message translates to:
  /// **'Actual (Cones)'**
  String get actualQtyCones;

  /// No description provided for @pallets.
  ///
  /// In en, this message translates to:
  /// **'Pallets'**
  String get pallets;

  /// No description provided for @supplierBatch.
  ///
  /// In en, this message translates to:
  /// **'SUPPLIER BATCH'**
  String get supplierBatch;

  /// No description provided for @selectWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Select Warehouse'**
  String get selectWarehouse;

  /// No description provided for @noMaterialsYet.
  ///
  /// In en, this message translates to:
  /// **'No materials added yet'**
  String get noMaterialsYet;

  /// No description provided for @confirmDeleteDetailMsg.
  ///
  /// In en, this message translates to:
  /// **'Deleting this line will update PO quantities. Continue?'**
  String get confirmDeleteDetailMsg;

  /// No description provided for @searchStockInHint.
  ///
  /// In en, this message translates to:
  /// **'Search Receipt No, PO, Container...'**
  String get searchStockInHint;

  /// No description provided for @createStockIn.
  ///
  /// In en, this message translates to:
  /// **'CREATE RECEIPT'**
  String get createStockIn;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @noStockInFound.
  ///
  /// In en, this message translates to:
  /// **'No stock in receipts found for this period.'**
  String get noStockInFound;

  /// No description provided for @containerSeal.
  ///
  /// In en, this message translates to:
  /// **'Container / Seal'**
  String get containerSeal;

  /// No description provided for @confirmDeleteStockIn.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete receipt {number}?'**
  String confirmDeleteStockIn(String number);

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorLabel(String message);

  /// No description provided for @errorLoadMaterials.
  ///
  /// In en, this message translates to:
  /// **'Error loading materials: {error}'**
  String errorLoadMaterials(String error);

  /// No description provided for @actualImportLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTUAL IMPORT'**
  String get actualImportLabel;

  /// No description provided for @errorNegative.
  ///
  /// In en, this message translates to:
  /// **'Cannot be negative'**
  String get errorNegative;

  /// No description provided for @batchManagement.
  ///
  /// In en, this message translates to:
  /// **'Batch Management'**
  String get batchManagement;

  /// No description provided for @batchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track raw material batches & QC status'**
  String get batchSubtitle;

  /// No description provided for @addBatch.
  ///
  /// In en, this message translates to:
  /// **'ADD BATCH'**
  String get addBatch;

  /// No description provided for @searchBatchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by Batch No...'**
  String get searchBatchHint;

  /// No description provided for @internalCode.
  ///
  /// In en, this message translates to:
  /// **'INTERNAL CODE'**
  String get internalCode;

  /// No description provided for @originCountry.
  ///
  /// In en, this message translates to:
  /// **'ORIGIN'**
  String get originCountry;

  /// No description provided for @qcStatus.
  ///
  /// In en, this message translates to:
  /// **'QC STATUS'**
  String get qcStatus;

  /// No description provided for @qcNote.
  ///
  /// In en, this message translates to:
  /// **'QC NOTE'**
  String get qcNote;

  /// No description provided for @traceability.
  ///
  /// In en, this message translates to:
  /// **'TRACEABILITY'**
  String get traceability;

  /// No description provided for @linkedReceipt.
  ///
  /// In en, this message translates to:
  /// **'Linked to Receipt'**
  String get linkedReceipt;

  /// No description provided for @linkedReceiptId.
  ///
  /// In en, this message translates to:
  /// **'Linked Receipt Detail ID'**
  String get linkedReceiptId;

  /// No description provided for @linkedReceiptIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter ID of Material Receipt Detail (Optional)'**
  String get linkedReceiptIdHelper;

  /// No description provided for @mfgDate.
  ///
  /// In en, this message translates to:
  /// **'Mfg Date'**
  String get mfgDate;

  /// No description provided for @expDate.
  ///
  /// In en, this message translates to:
  /// **'Exp Date'**
  String get expDate;

  /// No description provided for @qualityControl.
  ///
  /// In en, this message translates to:
  /// **'Quality Control'**
  String get qualityControl;

  /// No description provided for @generalNote.
  ///
  /// In en, this message translates to:
  /// **'General Note'**
  String get generalNote;

  /// No description provided for @isActiveBatchHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off if batch is cancelled or unused'**
  String get isActiveBatchHint;

  /// No description provided for @confirmDeleteBatchMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete batch {code}?'**
  String confirmDeleteBatchMsg(String code);

  /// No description provided for @noBatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No batches found'**
  String get noBatchesFound;

  /// No description provided for @unknownMaterial.
  ///
  /// In en, this message translates to:
  /// **'Unknown Material #{id}'**
  String unknownMaterial(int id);

  /// No description provided for @materialPurchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'Material Purchase Orders'**
  String get materialPurchaseOrders;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import/Export'**
  String get importExport;

  /// No description provided for @stockOutHeader.
  ///
  /// In en, this message translates to:
  /// **'Stock Out'**
  String get stockOutHeader;

  /// No description provided for @materialExport.
  ///
  /// In en, this message translates to:
  /// **'Material Export'**
  String get materialExport;

  /// No description provided for @semiFinishedExport.
  ///
  /// In en, this message translates to:
  /// **'Semi-finished Export'**
  String get semiFinishedExport;

  /// No description provided for @finishedProductExport.
  ///
  /// In en, this message translates to:
  /// **'Finished Product Export'**
  String get finishedProductExport;

  /// No description provided for @inventoryStock.
  ///
  /// In en, this message translates to:
  /// **'Inventory Stock'**
  String get inventoryStock;

  /// No description provided for @semiFinishedProducts.
  ///
  /// In en, this message translates to:
  /// **'Semi-finished Products'**
  String get semiFinishedProducts;

  /// No description provided for @finishedProducts.
  ///
  /// In en, this message translates to:
  /// **'Finished Products'**
  String get finishedProducts;

  /// No description provided for @materialBatches.
  ///
  /// In en, this message translates to:
  /// **'Material Batches'**
  String get materialBatches;

  /// No description provided for @weaving.
  ///
  /// In en, this message translates to:
  /// **'Weaving'**
  String get weaving;

  /// No description provided for @machineBasketInfo.
  ///
  /// In en, this message translates to:
  /// **'Machine & Basket Info'**
  String get machineBasketInfo;

  /// No description provided for @weavingManagement.
  ///
  /// In en, this message translates to:
  /// **'Weaving Management'**
  String get weavingManagement;

  /// No description provided for @dyeing.
  ///
  /// In en, this message translates to:
  /// **'Dyeing'**
  String get dyeing;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get printing;

  /// No description provided for @safeFinishedProducts.
  ///
  /// In en, this message translates to:
  /// **'Safe Finished Products'**
  String get safeFinishedProducts;

  /// No description provided for @packing.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get packing;

  /// No description provided for @rolling.
  ///
  /// In en, this message translates to:
  /// **'Rolling'**
  String get rolling;

  /// No description provided for @cutting.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get cutting;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminTitle;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember login'**
  String get rememberMe;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
