import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nara/app/app.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';
import 'package:nara/features/finance/presentation/providers/finance_providers.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/productivity/presentation/providers/productivity_providers.dart';
import 'package:nara/features/smart_scan/application/scan_gateways.dart';
import 'package:nara/features/smart_scan/domain/repositories/smart_scan_repository.dart';
import 'package:nara/features/smart_scan/presentation/providers/smart_scan_providers.dart';
import 'package:nara/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:nara/features/settings/presentation/pages/settings_page.dart';

import 'helpers/fake_foundation_repository.dart';
import 'helpers/fake_assistant_repository.dart';
import 'helpers/fake_finance_repository.dart';
import 'helpers/fake_productivity_repository.dart';
import 'helpers/fake_smart_scan.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  testWidgets('onboarding menyimpan profil lalu membuka dashboard', (
    tester,
  ) async {
    final repository = FakeFoundationRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang di Nara'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Yoga');
    await tester.tap(find.text('Mulai menggunakan Nara'));
    await tester.pumpAndSettle();

    expect(repository.profile?.name, 'Yoga');
    expect(find.text('Halo, Yoga'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('onboarding menolak nama kosong', (tester) async {
    await tester.pumpWidget(_testApp(FakeFoundationRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mulai menggunakan Nara'));
    await tester.pump();

    expect(find.text('Nama wajib diisi.'), findsOneWidget);
  });

  testWidgets('settings memperbarui tema dan profile lokal', (tester) async {
    final repository = FakeFoundationRepository(profile: _profile());
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Yoga'), findsOneWidget);

    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();

    expect(repository.preferences.theme.name, 'dark');
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });

  testWidgets('settings tetap dapat digunakan pada text scale 200 persen', (
    tester,
  ) async {
    final repository = FakeFoundationRepository(profile: _profile());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [foundationRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(2),
              ),
              child: const SettingsPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Backup lokal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('berpindah ke halaman keuangan', (tester) async {
    await tester.pumpWidget(
      _testApp(FakeFoundationRepository(profile: _profile())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-finance')));
    await tester.pumpAndSettle();

    expect(find.text('Keuangan'), findsWidgets);
    expect(find.text('Kelola uang Anda secara offline'), findsOneWidget);
  });

  testWidgets('dashboard memiliki menu keuangan jadwal dan task', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(FakeFoundationRepository(profile: _profile())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard-finance')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-schedule')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-task')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-schedule')));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal & Aktivitas'), findsOneWidget);
  });

  testWidgets('bottom navigation membuka asisten lokal', (tester) async {
    await tester.pumpWidget(
      _testApp(FakeFoundationRepository(profile: _profile())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-assistant')));
    await tester.pumpAndSettle();

    expect(find.text('Asisten Nara'), findsOneWidget);
    expect(find.text('Lokal • Offline'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-input')), findsOneWidget);
  });

  testWidgets('keuangan dapat membuat akun pertama', (tester) async {
    final financeRepository = FakeFinanceRepository();
    await tester.pumpWidget(
      _testApp(
        FakeFoundationRepository(profile: _profile()),
        financeRepository: financeRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-finance')));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada akun'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-name')),
      'Dompet Harian',
    );
    await tester.tap(find.text('Simpan akun'));
    await tester.pumpAndSettle();

    expect(find.text('Dompet Harian'), findsOneWidget);
  });

  testWidgets('navigasi memakai bottom bar pada layar ponsel', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(FakeFoundationRepository(profile: _profile())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(find.byKey(const ValueKey('nav-finance')));
    await tester.pumpAndSettle();
    expect(find.text('Kelola uang Anda secara offline'), findsOneWidget);
  });

  testWidgets('navigasi memakai rail pada layar lebar', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(FakeFoundationRepository(profile: _profile())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('task dapat dibuat dari form offline', (tester) async {
    await tester.pumpWidget(
      _testApp(FakeFoundationRepository(profile: _profile())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-task')));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada task'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-task')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-title')),
      'Selesaikan laporan',
    );
    await tester.tap(find.text('Simpan task'));
    await tester.pumpAndSettle();

    expect(find.text('Selesaikan laporan'), findsOneWidget);
  });

  testWidgets('asisten tidak menulis task sebelum konfirmasi', (tester) async {
    final productivity = FakeProductivityRepository();
    final assistant = FakeAssistantRepository();
    await tester.pumpWidget(
      _testApp(
        FakeFoundationRepository(profile: _profile()),
        productivityRepository: productivity,
        assistantRepository: assistant,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-assistant')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('assistant-input')),
      'Buat task laporan besok sore',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();

    expect(find.text('BELUM DISIMPAN'), findsOneWidget);
    expect(
      (await productivity.loadSnapshot(day: DateTime.now())).tasks,
      isEmpty,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('assistant-edit')));
    await tester.tap(find.byKey(const ValueKey('assistant-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('assistant-edit-title')),
      'Laporan revisi',
    );
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('assistant-confirm')));
    await tester.tap(find.byKey(const ValueKey('assistant-confirm')));
    await tester.pumpAndSettle();
    expect(
      (await productivity.loadSnapshot(day: DateTime.now())).tasks.single.title,
      'Laporan revisi',
    );
    expect(assistant.audits.last.status, 'success');
  });

  testWidgets('membatalkan preview tidak mengubah data', (tester) async {
    final productivity = FakeProductivityRepository();
    await tester.pumpWidget(
      _testApp(
        FakeFoundationRepository(profile: _profile()),
        productivityRepository: productivity,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-assistant')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('assistant-input')),
      'Buat task rahasia',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('assistant-cancel')));
    await tester.pumpAndSettle();

    expect(
      (await productivity.loadSnapshot(day: DateTime.now())).tasks,
      isEmpty,
    );
    expect(
      find.text('Tindakan dibatalkan. Tidak ada data yang disimpan.'),
      findsOneWidget,
    );
  });

  testWidgets('Smart Scan tidak menulis transaksi sebelum konfirmasi', (
    tester,
  ) async {
    final finance = _scanFinanceRepository();
    await tester.pumpWidget(
      _testApp(
        FakeFoundationRepository(profile: _profile()),
        financeRepository: finance,
        scanRepository: FakeSmartScanRepository(),
        scanPicker: FakeScanImagePicker(path: '/tmp/fixture-receipt.jpg'),
        scanOcr: FakeScanOcrEngine(
          'TOKO NARA\n14/07/2026\nTOTAL BAYAR Rp 25.000\nTUNAI Rp 30.000',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-smart-scan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-gallery')));
    await tester.pumpAndSettle();

    expect(find.text('Periksa draft'), findsOneWidget);
    expect(
      (await finance.loadSnapshot(month: DateTime.now())).transactions,
      isEmpty,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('scan-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-confirm')));
    await tester.pumpAndSettle();

    final transactions = (await finance.loadSnapshot(
      month: DateTime(2026, 7),
    )).transactions;
    expect(transactions, hasLength(1));
    expect(transactions.single.source, 'smart_scan');
  });
}

Widget _testApp(
  FakeFoundationRepository repository, {
  FakeFinanceRepository? financeRepository,
  FakeProductivityRepository? productivityRepository,
  FakeAssistantRepository? assistantRepository,
  SmartScanRepository? scanRepository,
  ScanImagePicker? scanPicker,
  ScanOcrEngine? scanOcr,
}) {
  return ProviderScope(
    overrides: [
      foundationRepositoryProvider.overrideWithValue(repository),
      financeRepositoryProvider.overrideWithValue(
        financeRepository ?? FakeFinanceRepository(),
      ),
      productivityRepositoryProvider.overrideWithValue(
        productivityRepository ?? FakeProductivityRepository(),
      ),
      reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
      assistantRepositoryProvider.overrideWithValue(
        assistantRepository ?? FakeAssistantRepository(),
      ),
      smartScanRepositoryProvider.overrideWithValue(
        scanRepository ?? FakeSmartScanRepository(),
      ),
      scanImagePickerProvider.overrideWithValue(
        scanPicker ?? FakeScanImagePicker(),
      ),
      scanImagePreprocessorProvider.overrideWithValue(FakeScanPreprocessor()),
      scanOcrEngineProvider.overrideWithValue(scanOcr ?? FakeScanOcrEngine('')),
    ],
    child: const NaraApp(),
  );
}

FakeFinanceRepository _scanFinanceRepository() {
  final now = DateTime.now();
  return FakeFinanceRepository(
    snapshot: FinanceSnapshot(
      accounts: [
        AccountBalance(
          account: FinanceAccount(
            id: 'cash',
            name: 'Tunai',
            type: FinanceAccountType.cash,
            openingBalance: 0,
            currency: 'IDR',
            isArchived: false,
            createdAt: now,
            updatedAt: now,
          ),
          balance: 0,
        ),
      ],
      categories: const [
        FinanceCategory(
          id: 'expense-shopping',
          name: 'Belanja',
          type: FinanceCategoryType.expense,
          icon: null,
          colorValue: null,
          isSystem: true,
        ),
      ],
      transactions: const [],
      savingGoals: const [],
      summary: const FinanceSummary(
        totalBalance: 0,
        monthlyIncome: 0,
        monthlyExpense: 0,
      ),
    ),
  );
}

UserProfile _profile() {
  final now = DateTime.utc(2026, 7, 14);
  return UserProfile(
    id: 'profile-1',
    name: 'Yoga',
    preferredLanguage: 'id',
    timezone: 'Asia/Jakarta',
    assistantName: 'Nara',
    createdAt: now,
    updatedAt: now,
  );
}
