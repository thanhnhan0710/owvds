// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get btnLogin => 'LOGIN';

  @override
  String welcome(String name) {
    return 'Welcome $name';
  }

  @override
  String get companyName => 'OPPERMANN VIETNAM CO., LTD.';

  @override
  String get erpSystemName => 'Enterprise Resource Planning System';

  @override
  String get loginSystemHeader => 'Login System';

  @override
  String get loginSubtitle => 'Sign in to continue to ERP System';

  @override
  String get copyright => '© 2026 Oppermann Vietnam';

  @override
  String get errorRequired => 'This field is required';

  @override
  String get errorLoginFailed => 'Login failed. Please check your credentials.';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorGeneric => 'A system error occurred';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get production => 'Production';

  @override
  String get inventory => 'Inventory';

  @override
  String get sales => 'Sales';

  @override
  String get hr => 'Human Resources';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get activePlans => 'Active Plans';

  @override
  String get lowStock => 'Low Stock Items';

  @override
  String get revenue => 'Revenue';

  @override
  String get recentActivities => 'Recent Activities';

  @override
  String get viewAll => 'View All';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get actions => 'Actions';

  @override
  String get required => 'Required';

  @override
  String get successAdded => 'Added successfully';

  @override
  String get successUpdated => 'Updated successfully';

  @override
  String get successDeleted => 'Deleted successfully';

  @override
  String get contact => 'Contact';

  @override
  String get processing => 'Processing...';

  @override
  String get note => 'Note';

  @override
  String get notice => 'Notice';

  @override
  String get featureUnderDevelopment =>
      'This feature is under development.\nPlease come back later.';

  @override
  String pageContent(String path) {
    return 'Page Content: $path';
  }

  @override
  String get erpSystemShort => 'ERP System';

  @override
  String get oppermannHeader => 'OPPERMANN';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get productionOutput => 'Production Output';

  @override
  String get justNow => 'Just now';

  @override
  String get statusDone => 'Done';

  @override
  String get departmentTitle => 'Departments';

  @override
  String get deptName => 'Department Name';

  @override
  String get deptDesc => 'Description';

  @override
  String get searchDept => 'Search Department...';

  @override
  String get addDept => 'Add Department';

  @override
  String get editDept => 'Edit Department';

  @override
  String get deleteDept => 'Delete Department';

  @override
  String confirmDelete(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get warehouseTitle => 'Warehouse Management';

  @override
  String get warehouseSubtitle => 'Manage storage locations & inventory';

  @override
  String get searchWarehouseHint => 'Search by name or location...';

  @override
  String get addWarehouse => 'Add Warehouse';

  @override
  String get editWarehouse => 'Edit Warehouse';

  @override
  String get deleteWarehouse => 'Delete Warehouse';

  @override
  String confirmDeleteWarehouse(String name) {
    return 'Are you sure you want to delete \'$name\'? This action cannot be undone.';
  }

  @override
  String get warehouseName => 'Warehouse Name';

  @override
  String get location => 'Location';

  @override
  String get description => 'Description';

  @override
  String get noWarehouseFound => 'No warehouses found';

  @override
  String get noDescription => 'No description';

  @override
  String get cannotOpenMap => 'Cannot open maps';

  @override
  String get employeeTitle => 'Employees';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get position => 'Position';

  @override
  String get department => 'Department';

  @override
  String get searchEmployee => 'Search employee...';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get deleteEmployee => 'Delete Employee';

  @override
  String confirmDeleteEmployee(String name) {
    return 'Delete employee $name?';
  }

  @override
  String get selectDept => 'Select Department';

  @override
  String get totalDepartments => 'Total Departments';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get members => 'Members';

  @override
  String get supplierTitle => 'Suppliers';

  @override
  String get supplierName => 'Supplier Name';

  @override
  String get searchSupplier => 'Search supplier...';

  @override
  String get addSupplier => 'Add Supplier';

  @override
  String get editSupplier => 'Edit Supplier';

  @override
  String get deleteSupplier => 'Delete Supplier';

  @override
  String confirmDeleteSupplier(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get paymentTerm => 'Payment Term';

  @override
  String get taxCode => 'Tax Code';

  @override
  String get leadTime => 'Lead Time';

  @override
  String get days => 'Days';

  @override
  String get contactPerson => 'Contact Person';

  @override
  String get shortName => 'Short Name';

  @override
  String get currency => 'Currency';

  @override
  String get originType => 'Origin Type';

  @override
  String get isActiveProvider => 'Is Active Provider?';

  @override
  String get yarnTitle => 'Yarn Inventory';

  @override
  String get yarnName => 'Yarn Name';

  @override
  String get itemCode => 'Item Code';

  @override
  String get yarnType => 'Type';

  @override
  String get color => 'Color';

  @override
  String get origin => 'Origin';

  @override
  String get supplier => 'Supplier';

  @override
  String get searchYarn => 'Search yarn (name, code)...';

  @override
  String get addYarn => 'Add Yarn';

  @override
  String get editYarn => 'Edit Yarn';

  @override
  String get deleteYarn => 'Delete Yarn';

  @override
  String confirmDeleteYarn(String name) {
    return 'Delete yarn $name?';
  }

  @override
  String get selectSupplier => 'Select Supplier';

  @override
  String get noYarnFound => 'No yarn items found';

  @override
  String get yarnLotTitle => 'Yarn Lots';

  @override
  String get lotCode => 'Lot Code';

  @override
  String get importDate => 'Import Date';

  @override
  String get totalKg => 'Total (kg)';

  @override
  String get rollCount => 'Rolls';

  @override
  String get warehouseLoc => 'Location';

  @override
  String get containerCode => 'Container';

  @override
  String get driver => 'Driver';

  @override
  String get receiver => 'Receiver';

  @override
  String get searchYarnLot => 'Search lot code...';

  @override
  String get addYarnLot => 'Add Yarn Lot';

  @override
  String get editYarnLot => 'Edit Yarn Lot';

  @override
  String get deleteYarnLot => 'Delete Yarn Lot';

  @override
  String confirmDeleteYarnLot(String code) {
    return 'Delete yarn lot $code?';
  }

  @override
  String get selectYarn => 'Select Yarn';

  @override
  String get selectEmployee => 'Select Employee';

  @override
  String get materialTitle => 'Materials';

  @override
  String get materialMaster => 'Materials Master';

  @override
  String get materialBreadcrumb => 'Inventory > Materials';

  @override
  String get materialName => 'Material Name';

  @override
  String get materialCode => 'Material Code';

  @override
  String get materialType => 'Type';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get importedBy => 'Imported By';

  @override
  String get searchMaterial => 'Search material...';

  @override
  String get searchMaterialHint => 'Search Code, Name...';

  @override
  String get totalMaterials => 'Total Materials';

  @override
  String get addMaterial => 'Add Material';

  @override
  String get editMaterial => 'Edit Material';

  @override
  String get deleteMaterial => 'Delete Material';

  @override
  String confirmDeleteMaterial(String name) {
    return 'Delete material $name?';
  }

  @override
  String get noMaterialFound => 'No materials found';

  @override
  String get selectImporter => 'Select Importer';

  @override
  String get selectUnit => 'Select Unit';

  @override
  String get hsCode => 'HS Code';

  @override
  String get denier => 'Denier';

  @override
  String get denierHint => 'Denier (e.g 1000D)';

  @override
  String get filament => 'Filament';

  @override
  String get minStock => 'Min Stock';

  @override
  String get uomBasePurchase => 'UOM Purchase (Base)';

  @override
  String get uomProduction => 'UOM Production';

  @override
  String get uomBP => 'UOM (B/P)';

  @override
  String get specs => 'Specs';

  @override
  String get unitTitle => 'Units of Measurement';

  @override
  String get unitName => 'Unit Name';

  @override
  String get searchUnit => 'Search unit...';

  @override
  String get addUnit => 'Add Unit';

  @override
  String get editUnit => 'Edit Unit';

  @override
  String get deleteUnit => 'Delete Unit';

  @override
  String confirmDeleteUnit(String name) {
    return 'Delete unit $name?';
  }

  @override
  String get noUnitFound => 'No units found';

  @override
  String get machineTitle => 'Machines';

  @override
  String get machineName => 'Machine Name';

  @override
  String get totalLines => 'Total Lines';

  @override
  String get purpose => 'Purpose';

  @override
  String get area => 'Area';

  @override
  String get searchMachine => 'Search machine...';

  @override
  String get addMachine => 'Add Machine';

  @override
  String get editMachine => 'Edit Machine';

  @override
  String get deleteMachine => 'Delete Machine';

  @override
  String confirmDeleteMachine(String name) {
    return 'Delete machine $name?';
  }

  @override
  String get noMachineFound => 'No machines found';

  @override
  String get running => 'Running';

  @override
  String get stopped => 'Stopped';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get spinning => 'Spinning';

  @override
  String get yarnOut => 'Yarn Out';

  @override
  String get unassignedArea => 'Unassigned Area';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusSpinning => 'Spinning';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusMaintenance => 'Maintenance';

  @override
  String get viewHistory => 'View History';

  @override
  String machineHistoryTitle(String name) {
    return 'History: $name';
  }

  @override
  String get noHistoryData => 'No activity history available.';

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String durationFormatMin(String min) {
    return '$min min';
  }

  @override
  String durationFormatHour(int hour, int min) {
    return '${hour}h ${min}m';
  }

  @override
  String get timeCurrent => 'Now';

  @override
  String changeStatusTitle(String status) {
    return 'Change Status: $status';
  }

  @override
  String confirmStatusChangeMsg(String name, String status) {
    return 'Do you want to change machine $name to $status?';
  }

  @override
  String get reasonIssue => 'Reason / Issue Description';

  @override
  String get enterReason =>
      'Enter reason (e.g. Broken thread, Motor failure...)';

  @override
  String get reasonRequired => 'Please enter a reason';

  @override
  String get captureEvidence => 'Capture Evidence';

  @override
  String get openingCamera => 'Opening Camera...';

  @override
  String get cameraFeatureDev => 'Camera feature is under development';

  @override
  String get shiftTitle => 'Work Shifts';

  @override
  String get shiftName => 'Shift Name';

  @override
  String get searchShift => 'Search shift...';

  @override
  String get addShift => 'Add Shift';

  @override
  String get editShift => 'Edit Shift';

  @override
  String get deleteShift => 'Delete Shift';

  @override
  String confirmDeleteShift(String name) {
    return 'Delete shift $name?';
  }

  @override
  String get noShiftFound => 'No shifts found';

  @override
  String get basketTitle => 'Baskets';

  @override
  String get basketCode => 'Basket Code';

  @override
  String get basketTitleVS2 => 'Basket';

  @override
  String get basketBreadcrumb => 'Inventory > Baskets';

  @override
  String get totalBaskets => 'Total Baskets';

  @override
  String get tareWeight => 'Tare Weight (kg)';

  @override
  String get searchBasket => 'Search basket...';

  @override
  String get addBasket => 'Add Basket';

  @override
  String get editBasket => 'Edit Basket';

  @override
  String get deleteBasket => 'Delete Basket';

  @override
  String confirmDeleteBasket(String code) {
    return 'Delete basket $code?';
  }

  @override
  String get noBasketFound => 'No baskets found';

  @override
  String basketFound(String code) {
    return 'Basket Found: $code';
  }

  @override
  String get basketNotFoundOrNotReady => 'Basket not found or NOT READY';

  @override
  String get stReady => 'Ready';

  @override
  String get stInUse => 'In Use';

  @override
  String get stHolding => 'Holding';

  @override
  String get stDamaged => 'Damaged';

  @override
  String get errorTareWeightInvalid => 'Tare weight must be greater than 0';

  @override
  String get dyeColorTitle => 'Dye Colors';

  @override
  String get colorName => 'Color Name';

  @override
  String get hexCode => 'Hex Code';

  @override
  String get searchColor => 'Search color...';

  @override
  String get addColor => 'Add Color';

  @override
  String get editColor => 'Edit Color';

  @override
  String get deleteColor => 'Delete Color';

  @override
  String confirmDeleteColor(String name) {
    return 'Delete color $name?';
  }

  @override
  String get noColorFound => 'No colors found';

  @override
  String get invalidHex => 'Invalid Hex Code (e.g., #FF0000)';

  @override
  String get productTitle => 'Products';

  @override
  String get productImage => 'Image';

  @override
  String get searchProduct => 'Search product...';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String confirmDeleteProduct(String code) {
    return 'Delete product $code?';
  }

  @override
  String get noProductFound => 'No products found';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get standardTitle => 'Standards';

  @override
  String get standardCode => 'Standard Code';

  @override
  String get product => 'Product';

  @override
  String get dyeColor => 'Dye Color';

  @override
  String get width => 'Width (mm)';

  @override
  String get thickness => 'Thickness (mm)';

  @override
  String get strength => 'Strength (daN)';

  @override
  String get elongation => 'Elongation (%)';

  @override
  String get colorFastDry => 'Color Fastness (Dry)';

  @override
  String get colorFastWet => 'Color Fastness (Wet)';

  @override
  String get deltaE => 'Delta E';

  @override
  String get appearance => 'Appearance';

  @override
  String get weftDensity => 'Weft Density (pick/10cm)';

  @override
  String get weight => 'Weight (g/m)';

  @override
  String get searchStandard => 'Search standard...';

  @override
  String get addStandard => 'Add Standard';

  @override
  String get editStandard => 'Edit Standard';

  @override
  String get deleteStandard => 'Delete Standard';

  @override
  String confirmDeleteStandard(String code) {
    return 'Delete standard $code?';
  }

  @override
  String get noStandardFound => 'No standards found';

  @override
  String get scheduleTitle => 'Work Schedules';

  @override
  String get workDate => 'Work Date';

  @override
  String get employee => 'Employee';

  @override
  String get shift => 'Shift';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get searchSchedule => 'Search schedule...';

  @override
  String get addSchedule => 'Assign Schedule';

  @override
  String get editSchedule => 'Edit Schedule';

  @override
  String get deleteSchedule => 'Delete Schedule';

  @override
  String confirmDeleteSchedule(String name, String date) {
    return 'Delete schedule for $name on $date?';
  }

  @override
  String get noScheduleFound => 'No schedules found';

  @override
  String get filterDate => 'Filter by Date';

  @override
  String get errorDuplicateSchedule =>
      'Conflict: This employee already has a shift on this date.';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get weavingTicketTitle => 'Weaving Tickets';

  @override
  String get ticketCode => 'Ticket Code';

  @override
  String get loadDate => 'Load date';

  @override
  String get date => 'Date';

  @override
  String get timeIn => 'Time In';

  @override
  String get empIn => 'Emp In';

  @override
  String get timeOut => 'Time Out';

  @override
  String get empOut => 'Emp Out';

  @override
  String get tage => 'Tage weight';

  @override
  String get machineInfo => 'Machine / Line';

  @override
  String get yarnInfo => 'Yarn Lot / Date';

  @override
  String get standardData => 'Standard Specifications';

  @override
  String get weightInfo => 'Gross / Net / Tare';

  @override
  String get lengthKnots => 'Length (m) / Knots';

  @override
  String get employees => 'Operators';

  @override
  String get timeInOut => 'Time In / Out';

  @override
  String get inspections => 'QC Inspections';

  @override
  String get addTicket => 'New Ticket';

  @override
  String get stageName => 'Stage';

  @override
  String get gross => 'Gross Weight';

  @override
  String get density => 'Density';

  @override
  String get tension => 'Tension';

  @override
  String get bowing => 'Bowing';

  @override
  String get inspector => 'Inspector';

  @override
  String get noTicketSelected => 'Select a ticket to view details';

  @override
  String get deleteTicket => 'Delete Ticket';

  @override
  String confirmDeleteTicket(String code) {
    return 'Delete ticket $code?';
  }

  @override
  String get deleteInspection => 'Delete Inspection';

  @override
  String get machineAndMaterial => 'Machine & Material';

  @override
  String get generalInfo => 'General Info';

  @override
  String get personnel => 'Personnel';

  @override
  String get resultsUpdateOnly => 'Results (Update Only)';

  @override
  String get machineOperation => 'Machine Operation';

  @override
  String get selectProductBefore => 'Select the product first';

  @override
  String get line => 'Line';

  @override
  String get assignBasket => 'Assign Basket';

  @override
  String get selectBasket => 'Select Ready Basket';

  @override
  String get scanBarcode => 'Scan Barcode / Input Code';

  @override
  String get scanBarcodeSubline =>
      'Scan the basket code here to select your own items';

  @override
  String get addInspection => 'Add QC';

  @override
  String get viewTicket => 'View Ticket';

  @override
  String get editTicket => 'Edit ticket';

  @override
  String get currentBasket => 'Current Basket';

  @override
  String get noActiveBasket => 'No active basket';

  @override
  String get confirmRelease => 'Finish this ticket and release basket?';

  @override
  String get basketAssigned => 'Basket assigned successfully';

  @override
  String get releaseBasket => 'Release Basket / Finish Ticket';

  @override
  String get finishTicket => 'Finish Ticket';

  @override
  String get grossWeight => 'Gross Weight (kg)';

  @override
  String get netWeight => 'Net Weight (kg)';

  @override
  String get length => 'Length (m)';

  @override
  String get splice => 'Splice';

  @override
  String get bow => 'Bow';

  @override
  String get employeeOut => 'Receiver / Operator Out';

  @override
  String get ticketDetails => 'Ticket Details';

  @override
  String get inspectionHistory => 'Inspection History';

  @override
  String get newInspection => 'New Inspection';

  @override
  String get confirmReleaseTitle => 'Confirm Finish';

  @override
  String get confirmReleaseMsg =>
      'Are you sure you want to finish this ticket and release the basket?';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get noTicketsFoundForThisDate => 'No tickets found for this date';

  @override
  String get noBasket => 'No Basket';

  @override
  String get productionInfo => 'Production Info';

  @override
  String get timeAndPersonnel => 'Time & Personnel';

  @override
  String get output => 'Output';

  @override
  String get noInspectionsRecorded => 'No inspections recorded';

  @override
  String get inspection => 'Inspection';

  @override
  String get measurements => 'Measurements';

  @override
  String get userManagementTitle => 'User Management';

  @override
  String get searchUser => 'Search users (name, email)...';

  @override
  String get noUserFound => 'No users found.';

  @override
  String get lastLogin => 'Last Login';

  @override
  String get notLinked => 'Not Linked';

  @override
  String get superuser => 'SUPERUSER';

  @override
  String get never => 'Never';

  @override
  String get addUser => 'Add User';

  @override
  String get editUser => 'Edit User';

  @override
  String get addNewUser => 'Add New User';

  @override
  String get linkToEmployee => 'Link to Employee';

  @override
  String get linkEmployeeHelper =>
      'Select an employee to link with this account';

  @override
  String get noEmployeeLinkedOption => '--- No Employee Linked ---';

  @override
  String get passwordRequiredNew => 'Required for new user';

  @override
  String get newPasswordPlaceholder => 'New Password (Leave blank to keep)';

  @override
  String get role => 'Role';

  @override
  String get isActiveSwitch => 'Is Active';

  @override
  String get isSuperuserSwitch => 'Is Superuser';

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String confirmDeleteUserMsg(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get prodStatsTitle => 'Production Statistics';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get recalculateToday => 'Recalculate (Today)';

  @override
  String get searchProductHint => 'Search product code, note...';

  @override
  String get filterToday => 'Today';

  @override
  String get filterYesterday => 'Yesterday';

  @override
  String get filter7Days => 'Last 7 Days';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get filterLastMonth => 'Last Month';

  @override
  String get filterThisQuarter => 'This Quarter';

  @override
  String get filterThisYear => 'This Year';

  @override
  String get filterCustom => 'Custom Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get totalProduction => 'TOTAL PRODUCTION';

  @override
  String get totalLength => 'TOTAL LENGTH';

  @override
  String get itemCount => 'ITEMS';

  @override
  String get noStatsData => 'No data for this period';

  @override
  String get machines => 'Machines';

  @override
  String get copySuccess => 'Copied to clipboard!';

  @override
  String get exporting => 'Creating Excel file...';

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get purchaseOrderTitle => 'Purchase Orders';

  @override
  String get purchaseOrderSubtitle => 'Manage procurement and suppliers';

  @override
  String get createPO => 'CREATE PO';

  @override
  String get searchPO => 'Search PO Number...';

  @override
  String get poNumber => 'PO Number';

  @override
  String get vendor => 'Vendor';

  @override
  String get orderDate => 'Order Date';

  @override
  String get eta => 'Expected Arrival (ETA)';

  @override
  String get incoterm => 'Incoterm';

  @override
  String get exchangeRate => 'Exchange Rate';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get poDetailTitle => 'Purchase Order Detail';

  @override
  String get orderItems => 'Order Items';

  @override
  String get addItem => 'Add Item';

  @override
  String get noItemsPO => 'No items in this order yet.';

  @override
  String get addMaterialPrompt => 'Click \'+ Add Material\' to start.';

  @override
  String get materialInfo => 'MATERIAL INFORMATION';

  @override
  String get tapToSearch => 'Tap to search material...';

  @override
  String get transactionDetails => 'TRANSACTION DETAILS';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get lineTotal => 'Line Total';

  @override
  String get estimatedTotal => 'Estimated Total';

  @override
  String get confirmAdd => 'Confirm Add';

  @override
  String get searchMaterialPlaceholder => 'Type name, code, specs...';

  @override
  String get deletePO => 'Delete PO';

  @override
  String confirmDeletePO(String number) {
    return 'Are you sure you want to delete PO $number?';
  }

  @override
  String get bomTitle => 'BOM Management';

  @override
  String get bomSubtitle => 'Production > Bill of Materials';

  @override
  String get addBOM => 'ADD BOM';

  @override
  String get noBOMFound => 'No BOM configurations found';

  @override
  String get bomCode => 'BOM Code';

  @override
  String get bomName => 'BOM Name';

  @override
  String get baseQty => 'Base Qty';

  @override
  String get version => 'Version';

  @override
  String get viewIngredients => 'View Ingredients';

  @override
  String get newBOM => 'New BOM';

  @override
  String get editBOM => 'Edit BOM Header';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get chooseProduct => 'Choose a product';

  @override
  String get loadingProducts => 'Loading products...';

  @override
  String get setActiveVersion => 'Set as Active Version';

  @override
  String get bomCodeRequired => 'BOM Code is required';

  @override
  String get productRequired => 'Please select a Product!';

  @override
  String get deleteBOM => 'Delete BOM';

  @override
  String confirmDeleteBOM(String code) {
    return 'Delete BOM $code? This will remove all material details.';
  }

  @override
  String get bomIngredientsConfig => 'BOM Ingredients Config';

  @override
  String get matId => 'Mat ID';

  @override
  String get ends => 'Ends';

  @override
  String get stdQty => 'Std';

  @override
  String get wastage => 'Waste';

  @override
  String get grossQty => 'Gross';

  @override
  String get saveDetail => 'Save Detail';

  @override
  String get editMaterialDetail => 'Edit Material Detail';

  @override
  String get importDeclarationTitle => 'Import Declarations';

  @override
  String get importDeclarationSubtitle =>
      'Manage customs declarations (E31, A11...)';

  @override
  String get newDeclaration => 'NEW DECLARATION';

  @override
  String get searchDeclarationHint => 'Search No, Invoice, B/L...';

  @override
  String get noDeclarationFound => 'No declarations found';

  @override
  String get declarationNo => 'Declaration No';

  @override
  String get declarationDate => 'Declaration Date';

  @override
  String get declarationType => 'Type';

  @override
  String get invoiceBill => 'Invoice / Bill';

  @override
  String get totalTax => 'Total Tax';

  @override
  String get invoiceAbbr => 'Inv';

  @override
  String get billOfLadingAbbr => 'B/L';

  @override
  String get invoiceNo => 'Invoice No';

  @override
  String get billOfLading => 'Bill of Lading';

  @override
  String get createDeclaration => 'Create Declaration';

  @override
  String get editDeclaration => 'Edit Declaration';

  @override
  String get totalTaxAmount => 'Total Tax Amount';

  @override
  String get deleteDeclaration => 'Delete Declaration';

  @override
  String confirmDeleteDeclaration(String number) {
    return 'Are you sure you want to delete declaration $number?';
  }

  @override
  String get declarationDetailTitle => 'Declaration Details';

  @override
  String get declarationItemsList => 'Cargo List';

  @override
  String get addDeclarationItem => 'Add Item';

  @override
  String get noDeclarationItems => 'No items in this declaration.';

  @override
  String get addDeclarationItemPrompt => 'Click \'+ Add Item\' to start.';

  @override
  String get editDeclarationItem => 'Edit Item';

  @override
  String get addDeclarationItemTitle => 'Add Item to Declaration';

  @override
  String get materialLabel => 'Material';

  @override
  String get selectMaterialPlaceholder => 'Select material...';

  @override
  String get actualHSCode => 'HS Code (Actual)';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitPriceLabel => 'Unit Price';

  @override
  String get errorSelectMaterial => 'Please select a material!';

  @override
  String get searchMaterialTitle => 'Search Material';

  @override
  String get deleteItemTitle => 'Delete Item';

  @override
  String get confirmDeleteItemMsg =>
      'Are you sure you want to delete this item?';

  @override
  String get registrationDate => 'Reg. Date';

  @override
  String get updateAction => 'Update';

  @override
  String get stockInTitle => 'Stock In';

  @override
  String get stockInSubtitle => 'Manage stock in receipts';

  @override
  String get tabMaterial => 'Materials';

  @override
  String get tabSemiFinished => 'Semi-finished';

  @override
  String get tabFinished => 'Finished Goods';

  @override
  String get goodsList => 'Goods List';

  @override
  String get addRow => 'Add Row';

  @override
  String get saveReceipt => 'SAVE RECEIPT';

  @override
  String get receiptNumber => 'Receipt No';

  @override
  String get receivingWarehouse => 'Receiving Warehouse';

  @override
  String get sendingDepartment => 'Sending Dept';

  @override
  String get semiFinishedCode => 'Code';

  @override
  String get semiFinishedName => 'Name';

  @override
  String get goodQty => 'Good Qty';

  @override
  String get badQty => 'Bad Qty';

  @override
  String get source => 'Source';

  @override
  String get carton => 'Carton/Bundle';

  @override
  String get selectPlaceholder => 'Select...';

  @override
  String get cancelAction => 'Cancel';

  @override
  String generalInfoTitle(String title) {
    return 'General Info - $title';
  }

  @override
  String get createReceiptTitle => 'Create New Receipt';

  @override
  String get editReceiptTitle => 'Receipt Details';

  @override
  String get logisticsInfo => 'Logistics Info';

  @override
  String get byPO => 'By Purchase Order (PO)';

  @override
  String get customsDeclarationOptional => 'Customs Declaration (Optional)';

  @override
  String get noSelection => '--- No Selection ---';

  @override
  String get loadingDeclaration => 'Loading declarations...';

  @override
  String get createdBy => 'Created By';

  @override
  String get containerNumber => 'Container No';

  @override
  String get sealNumber => 'Seal No';

  @override
  String get poQtyKg => 'PO Qty (Kg)';

  @override
  String get poQtyCones => 'PO Qty (Cones)';

  @override
  String get actualQtyKg => 'Actual (Kg)';

  @override
  String get actualQtyCones => 'Actual (Cones)';

  @override
  String get pallets => 'Pallets';

  @override
  String get supplierBatch => 'SUPPLIER BATCH';

  @override
  String get selectWarehouse => 'Select Warehouse';

  @override
  String get noMaterialsYet => 'No materials added yet';

  @override
  String get confirmDeleteDetailMsg =>
      'Deleting this line will update PO quantities. Continue?';

  @override
  String get searchStockInHint => 'Search Receipt No, PO, Container...';

  @override
  String get createStockIn => 'CREATE RECEIPT';

  @override
  String get reload => 'Reload';

  @override
  String get noStockInFound => 'No stock in receipts found for this period.';

  @override
  String get containerSeal => 'Container / Seal';

  @override
  String confirmDeleteStockIn(String number) {
    return 'Are you sure you want to delete receipt $number?';
  }

  @override
  String errorLabel(String message) {
    return 'Error: $message';
  }

  @override
  String errorLoadMaterials(String error) {
    return 'Error loading materials: $error';
  }

  @override
  String get actualImportLabel => 'ACTUAL IMPORT';

  @override
  String get errorNegative => 'Cannot be negative';

  @override
  String get batchManagement => 'Batch Management';

  @override
  String get batchSubtitle => 'Track raw material batches & QC status';

  @override
  String get addBatch => 'ADD BATCH';

  @override
  String get searchBatchHint => 'Search by Batch No...';

  @override
  String get internalCode => 'INTERNAL CODE';

  @override
  String get originCountry => 'ORIGIN';

  @override
  String get qcStatus => 'QC STATUS';

  @override
  String get qcNote => 'QC NOTE';

  @override
  String get traceability => 'TRACEABILITY';

  @override
  String get linkedReceipt => 'Linked to Receipt';

  @override
  String get linkedReceiptId => 'Linked Receipt Detail ID';

  @override
  String get linkedReceiptIdHelper =>
      'Enter ID of Material Receipt Detail (Optional)';

  @override
  String get mfgDate => 'Mfg Date';

  @override
  String get expDate => 'Exp Date';

  @override
  String get qualityControl => 'Quality Control';

  @override
  String get generalNote => 'General Note';

  @override
  String get isActiveBatchHint => 'Turn off if batch is cancelled or unused';

  @override
  String confirmDeleteBatchMsg(String code) {
    return 'Are you sure you want to delete batch $code?';
  }

  @override
  String get noBatchesFound => 'No batches found';

  @override
  String unknownMaterial(int id) {
    return 'Unknown Material #$id';
  }

  @override
  String get materialPurchaseOrders => 'Material Purchase Orders';

  @override
  String get importExport => 'Import/Export';

  @override
  String get stockOutHeader => 'Stock Out';

  @override
  String get materialExport => 'Material Export';

  @override
  String get semiFinishedExport => 'Semi-finished Export';

  @override
  String get finishedProductExport => 'Finished Product Export';

  @override
  String get inventoryStock => 'Inventory Stock';

  @override
  String get semiFinishedProducts => 'Semi-finished Products';

  @override
  String get finishedProducts => 'Finished Products';

  @override
  String get materialBatches => 'Material Batches';

  @override
  String get weaving => 'Weaving';

  @override
  String get machineBasketInfo => 'Machine & Basket Info';

  @override
  String get weavingManagement => 'Weaving Management';

  @override
  String get dyeing => 'Dyeing';

  @override
  String get printing => 'Printing';

  @override
  String get safeFinishedProducts => 'Safe Finished Products';

  @override
  String get packing => 'Packing';

  @override
  String get rolling => 'Rolling';

  @override
  String get cutting => 'Cutting';

  @override
  String get adminTitle => 'Administrator';

  @override
  String get activityLog => 'Activity Log';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get rememberMe => 'Remember login';
}
