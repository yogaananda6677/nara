import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

DateTime _utcNow() => DateTime.now().toUtc();

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get preferredLanguage =>
      text().withDefault(const Constant('id'))();
  TextColumn get timezone =>
      text().withDefault(const Constant('Asia/Jakarta'))();
  TextColumn get assistantName => text().withDefault(const Constant('Nara'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text().withDefault(const Constant('cash'))();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get colorValue => integer().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TransactionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get transferPairId => text().nullable()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get merchant => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get scanId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SavingGoals extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  IntColumn get targetAmount => integer()();
  IntColumn get initialAmount => integer().withDefault(const Constant(0))();
  IntColumn get savedAmount => integer().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get parentTaskId => text().nullable().references(Tasks, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get repeatRule => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get repeatRule => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get category => text().nullable()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get mood => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ToolAudits extends Table {
  TextColumn get id => text()();
  TextColumn get toolName => text()();
  TextColumn get action => text()();
  TextColumn get targetId => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AssistantConversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AssistantMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(AssistantConversations, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get intent => text().nullable()();
  TextColumn get toolName => text().nullable()();
  TextColumn get toolArguments => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SmartScans extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get documentType => text()();
  RealColumn get confidence => real()();
  TextColumn get status => text()();
  IntColumn get extractedAmount => integer().nullable()();
  TextColumn get merchant => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class SecurityCredentials extends Table {
  TextColumn get id => text()();
  TextColumn get pinHash => text()();
  TextColumn get pinSalt => text()();
  IntColumn get kdfIterations => integer()();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Profiles,
    Accounts,
    Categories,
    TransactionEntries,
    SavingGoals,
    Tasks,
    Schedules,
    ActivityLogs,
    Reminders,
    ToolAudits,
    AssistantConversations,
    AssistantMessages,
    SmartScans,
    AppSettings,
    SecurityCredentials,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'nara'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  Future<bool> integrityCheck() async {
    final rows = await customSelect('PRAGMA quick_check').get();
    return rows.isNotEmpty &&
        rows.every((row) => row.data.values.singleOrNull == 'ok');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(savingGoals, savingGoals.savedAmount);
        await customStatement(
          'UPDATE saving_goals SET saved_amount = initial_amount',
        );
      }
      if (from < 3) {
        await migrator.addColumn(tasks, tasks.category);
      }
      if (from < 4) {
        await migrator.createTable(assistantConversations);
        await migrator.createTable(assistantMessages);
      }
      if (from < 5) {
        await migrator.createTable(smartScans);
      }
      if (from < 6) {
        await migrator.createTable(securityCredentials);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
