// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje
//
// Minimal zero-dependency test harness (QtTest is not packaged in the
// Sailfish target). Run with scripts/run-tests.sh, or from an SDK build shell:
//   cd tests/tst_core && qmake && make && ./tst_core

#include "core/database.h"
#include "core/scheduleengine.h"
#include "core/store.h"

#include <QCoreApplication>
#include <QDate>
#include <QDebug>
#include <QDir>
#include <QTemporaryDir>
#include <QTime>

#include <ctime>
#include <cstdio>

using namespace dollfin;

static int g_checks = 0;
static int g_failures = 0;

static void reportFailure(const char *file, int line, const char *expression, const QString &detail = QString())
{
    ++g_failures;
    std::fprintf(stderr, "FAIL %s:%d: %s%s%s\n", file, line, expression,
                 detail.isEmpty() ? "" : " -- ", detail.toUtf8().constData());
    std::fflush(stderr);
}

#define CHECK(cond)                                                        \
    do {                                                                   \
        ++g_checks;                                                        \
        if (!(cond))                                                       \
            reportFailure(__FILE__, __LINE__, #cond);                      \
    } while (0)

#define CHECK_EQ(actual, expected)                                                    \
    do {                                                                              \
        ++g_checks;                                                                   \
        const auto a_ = (actual);                                                     \
        const auto e_ = (expected);                                                   \
        if (!(a_ == e_)) {                                                            \
            QString detail;                                                           \
            QDebug(&detail) << "got" << a_ << "expected" << e_;                     \
            reportFailure(__FILE__, __LINE__, #actual " == " #expected, detail);      \
        }                                                                             \
    } while (0)

static void useTimezone(const char *tz)
{
    qputenv("TZ", tz);
    tzset();
}

static QDate med(const char *iso)
{
    return QDate::fromString(QString::fromLatin1(iso), Qt::ISODate);
}

static QDateTime utc(const char *iso)
{
    return QDateTime(QDate::fromString(QString::fromLatin1(iso).left(10), Qt::ISODate),
                     QTime::fromString(QString::fromLatin1(iso).mid(11, 5), QStringLiteral("HH:mm")),
                     Qt::UTC);
}

static void testSchemaAndMigration()
{
    QTemporaryDir dir;
    Database db;
    QString error;
    const bool openOk = db.open(dir.path() + "/schema.db", &error);
    if (!openOk)
        std::fprintf(stderr, "open failed: %s\n", error.toUtf8().constData());
    CHECK(openOk);
    CHECK_EQ(db.schemaVersion(), 1);

    // Re-opening an existing database must not re-run migrations.
    db.close();
    Database db2;
    CHECK(db2.open(dir.path() + "/schema.db", &error));
    CHECK_EQ(db2.schemaVersion(), 1);
}

static void testMedicationCrud()
{
    QTemporaryDir dir;
    Database db;
    CHECK(db.open(dir.path() + "/med.db"));
    Store store(db);

    Medication m;
    m.name = QStringLiteral("Estradiol hemihydrate (compounded) 2 mg"); // free text, D-017
    m.form = QStringLiteral("tablet");
    m.strength = 2.0;
    m.unit = QStringLiteral("mg");
    CHECK(store.addMedication(m));
    CHECK(m.id > 0);

    Medication other;
    other.name = QStringLiteral("Testosterone gel");
    CHECK(store.addMedication(other));

    CHECK_EQ(store.medications().size(), 2);

    m.notes = QStringLiteral("take sublingually");
    CHECK(store.updateMedication(m));

    bool ok = false;
    const Medication fetched = store.medication(m.id, &ok);
    CHECK(ok);
    CHECK(fetched.notes == QStringLiteral("take sublingually"));
    CHECK_EQ(fetched.strength, 2.0);

    CHECK(store.removeMedication(other.id));
    CHECK_EQ(store.medications().size(), 1);
    store.medication(other.id, &ok);
    CHECK(!ok);
}

static void testRegimenCrudAndCascade()
{
    QTemporaryDir dir;
    Database db;
    CHECK(db.open(dir.path() + "/reg.db"));
    Store store(db);

    Medication m;
    m.name = QStringLiteral("Estradiol valerate");
    CHECK(store.addMedication(m));

    Regimen r;
    r.medicationId = m.id;
    r.dose = 5.0;
    r.unit = QStringLiteral("mg");
    r.route = QStringLiteral("injection");
    r.intervalDays = 5;
    r.times = QList<QTime>() << QTime(8, 0) << QTime(20, 0);
    r.startDate = med("2026-01-01");
    CHECK(store.addRegimen(r));
    CHECK(r.id > 0);

    bool ok = false;
    const Regimen fetched = store.regimen(r.id, &ok);
    CHECK(ok);
    CHECK_EQ(fetched.times.size(), 2);
    CHECK_EQ(fetched.intervalDays, 5);
    CHECK_EQ(fetched.route, QStringLiteral("injection"));

    // Weekly regimen with explicit weekdays.
    Regimen weekly;
    weekly.medicationId = m.id;
    weekly.times = QList<QTime>() << QTime(9, 0);
    weekly.daysOfWeek = QList<int>() << 1 << 3 << 5;
    weekly.startDate = med("2026-01-05");
    CHECK(store.addRegimen(weekly));
    const Regimen w = store.regimen(weekly.id, &ok);
    CHECK(ok);
    CHECK_EQ(w.daysOfWeek.size(), 3);

    // Removing the medication cascades to its regimens.
    CHECK_EQ(store.regimens(m.id).size(), 2);
    CHECK(store.removeMedication(m.id));
    CHECK_EQ(store.regimens().size(), 0);
}

static void testIntakeCrud()
{
    QTemporaryDir dir;
    Database db;
    QString error;
    const bool openOk = db.open(dir.path() + "/intake.db", &error);
    if (!openOk)
        std::fprintf(stderr, "intake open failed: %s\n", error.toUtf8().constData());
    CHECK(openOk);
    Store store(db);

    Medication m;
    m.name = QStringLiteral("Progesterone");
    CHECK(store.addMedication(m));

    Intake i;
    i.medicationId = m.id;
    i.regimenId = -1;
    i.takenAt = utc("2026-02-01T21:00");
    i.amount = 100.0;
    i.unit = QStringLiteral("mg");
    i.status = QStringLiteral("taken");
    CHECK(store.addIntake(i));
    CHECK(i.id > 0);

    CHECK_EQ(store.intakes().size(), 1);
    const QList<Intake> list = store.intakes(m.id);
    CHECK_EQ(list.size(), 1);
    if (!list.isEmpty()) {
        const Intake f = list.first();
        CHECK(f.status == QStringLiteral("taken"));
        CHECK_EQ(f.amount, 100.0);
        CHECK(f.takenAt.toUTC().toString(Qt::ISODate) == QStringLiteral("2026-02-01T21:00:00Z"));
    }

    Intake skipped;
    skipped.medicationId = m.id;
    skipped.regimenId = -1;
    skipped.takenAt = utc("2026-02-02T21:00");
    skipped.status = QStringLiteral("skipped");
    CHECK(store.addIntake(skipped));
    CHECK_EQ(store.intakes().size(), 2);

    CHECK(store.removeIntake(i.id));
    CHECK_EQ(store.intakes().size(), 1);
}

static Regimen dailyRegimen()
{
    Regimen r;
    r.active = true;
    r.intervalDays = 1;
    r.times = QList<QTime>() << QTime(8, 0) << QTime(20, 0);
    r.startDate = med("2026-01-01");
    return r;
}

static void testScheduleDaily()
{
    const Regimen r = dailyRegimen();
    const QList<QDateTime> occ = ScheduleEngine::occurrences(r, utc("2026-01-01T00:00"), utc("2026-01-04T00:00"));
    CHECK_EQ(occ.size(), 6);
    // Sorted ascending.
    CHECK(occ.first() < occ.last());
}

static void testScheduleInterval()
{
    Regimen r = dailyRegimen();
    r.intervalDays = 3;
    r.times = QList<QTime>() << QTime(9, 0);
    const QList<QDateTime> occ = ScheduleEngine::occurrences(r, utc("2026-01-01T00:00"), utc("2026-01-11T00:00"));
    CHECK_EQ(occ.size(), 4); // Jan 1, 4, 7, 10
}

static void testScheduleWeekdays()
{
    Regimen r;
    r.active = true;
    r.times = QList<QTime>() << QTime(10, 0);
    r.daysOfWeek = QList<int>() << 1 << 3 << 5; // Mon, Wed, Fri
    r.startDate = med("2026-01-05");            // a Monday
    const QList<QDateTime> occ = ScheduleEngine::occurrences(r, utc("2026-01-05T00:00"), utc("2026-01-12T00:00"));
    CHECK_EQ(occ.size(), 3); // Mon 5, Wed 7, Fri 9
}

static void testScheduleEndDateAndInactive()
{
    Regimen r = dailyRegimen();
    r.times = QList<QTime>() << QTime(8, 0);
    r.endDate = med("2026-01-03");
    CHECK_EQ(ScheduleEngine::occurrences(r, utc("2026-01-01T00:00"), utc("2026-01-31T00:00")).size(), 3);

    r.active = false;
    CHECK_EQ(ScheduleEngine::occurrences(r, utc("2026-01-01T00:00"), utc("2026-01-31T00:00")).size(), 0);
}

static void testScheduleStartInFuture()
{
    Regimen r = dailyRegimen();
    r.startDate = med("2026-06-01");
    CHECK_EQ(ScheduleEngine::occurrences(r, utc("2026-01-01T00:00"), utc("2026-02-01T00:00")).size(), 0);
}

static void testScheduleMonthYearBoundary()
{
    Regimen r = dailyRegimen();
    r.times = QList<QTime>() << QTime(23, 0);
    r.startDate = med("2026-12-31");
    const QList<QDateTime> occ = ScheduleEngine::occurrences(r, utc("2026-12-31T00:00"), utc("2027-01-03T00:00"));
    CHECK_EQ(occ.size(), 3); // Dec 31, Jan 1, Jan 2
}

static void testScheduleDst()
{
    useTimezone("Europe/Berlin");
    Regimen r = dailyRegimen();
    r.times = QList<QTime>() << QTime(12, 0);
    r.startDate = med("2026-03-28");
    const QList<QDateTime> occ = ScheduleEngine::occurrences(r, utc("2026-03-28T00:00"), utc("2026-03-31T00:00"));
    CHECK_EQ(occ.size(), 3); // DST spring-forward on 2026-03-29 must not drop or duplicate a day
    if (occ.size() == 3) {
        // 12:00 CET = 11:00 UTC; after the change 12:00 CEST = 10:00 UTC.
        CHECK_EQ(occ[0].toUTC().time().hour(), 11);
        CHECK_EQ(occ[2].toUTC().time().hour(), 10);
    }
    useTimezone("UTC");
}

static void testFirstOccurrenceAfter()
{
    const Regimen r = dailyRegimen();
    const QDateTime next = ScheduleEngine::firstOccurrenceAfter(r, utc("2026-01-02T09:00"));
    CHECK(next.isValid());
    CHECK(next > utc("2026-01-02T09:00"));
    CHECK_EQ(next.toUTC().toString(Qt::ISODate), QStringLiteral("2026-01-02T20:00:00Z"));

    Regimen paused = r;
    paused.active = false;
    CHECK(!ScheduleEngine::firstOccurrenceAfter(paused, utc("2026-01-02T09:00")).isValid());
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    useTimezone("UTC");

    testSchemaAndMigration();
    testMedicationCrud();
    testRegimenCrudAndCascade();
    testIntakeCrud();
    testScheduleDaily();
    testScheduleInterval();
    testScheduleWeekdays();
    testScheduleEndDateAndInactive();
    testScheduleStartInFuture();
    testScheduleMonthYearBoundary();
    testScheduleDst();
    testFirstOccurrenceAfter();

    std::fprintf(stderr, "%d checks, %d failure(s)\n", g_checks, g_failures);
    return g_failures == 0 ? 0 : 1;
}
