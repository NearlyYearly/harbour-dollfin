// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#include "appcontroller.h"

#include "core/scheduleengine.h"

#include <QDate>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTime>
#include <algorithm>

namespace dollfin {
namespace {

QVariantMap medicationToMap(const Medication &m)
{
    QVariantMap map;
    map[QStringLiteral("id")] = m.id;
    map[QStringLiteral("name")] = m.name;
    map[QStringLiteral("form")] = m.form;
    map[QStringLiteral("strength")] = m.strength;
    map[QStringLiteral("unit")] = m.unit;
    map[QStringLiteral("notes")] = m.notes;
    map[QStringLiteral("active")] = m.active;
    QString detail;
    if (m.strength > 0.0)
        detail = QString::number(m.strength) + QLatin1Char(' ') + m.unit;
    else
        detail = m.unit;
    if (!m.form.isEmpty())
        detail = detail.isEmpty() ? m.form : (m.form + QStringLiteral(" · ") + detail);
    map[QStringLiteral("detail")] = detail.trimmed();
    return map;
}

QString timesToJson(const QList<QTime> &times)
{
    QStringList parts;
    for (const QTime &time : times)
        parts.append(time.toString(QStringLiteral("HH:mm")));
    return parts.join(QLatin1Char(' '));
}

QVariantMap regimenToMap(const Regimen &r, const Medication &medication)
{
    QVariantList days;
    for (int day : r.daysOfWeek)
        days.append(day);
    QVariantList times;
    for (const QTime &time : r.times)
        times.append(time.toString(QStringLiteral("HH:mm")));

    // Dose/strength/route live on the medication, not the schedule.
    QString doseText;
    if (medication.strength > 0.0)
        doseText = QString::number(medication.strength) + QLatin1Char(' ') + medication.unit;
    else
        doseText = medication.unit;
    if (!medication.form.isEmpty())
        doseText = doseText.isEmpty() ? medication.form
                                      : (medication.form + QStringLiteral(" · ") + doseText);

    QVariantMap map;
    map[QStringLiteral("id")] = r.id;
    map[QStringLiteral("medicationId")] = r.medicationId;
    map[QStringLiteral("medicationName")] = medication.name;
    map[QStringLiteral("intervalDays")] = r.intervalDays;
    map[QStringLiteral("daysOfWeek")] = days;
    map[QStringLiteral("times")] = times;
    map[QStringLiteral("timesText")] = timesToJson(r.times);
    map[QStringLiteral("startDate")] = r.startDate.toString(Qt::ISODate);
    map[QStringLiteral("endDate")] = r.endDate.isValid() ? r.endDate.toString(Qt::ISODate) : QString();
    map[QStringLiteral("active")] = r.active;
    map[QStringLiteral("doseText")] = doseText.trimmed();
    return map;
}

QList<int> toDayList(const QVariantList &values)
{
    QList<int> days;
    for (const QVariant &value : values) {
        const int day = value.toInt();
        if (day >= 1 && day <= 7)
            days.append(day);
    }
    return days;
}

QList<QTime> toTimeList(const QVariantList &values)
{
    QList<QTime> times;
    for (const QVariant &value : values) {
        const QTime time = QTime::fromString(value.toString(), QStringLiteral("HH:mm"));
        if (time.isValid())
            times.append(time);
    }
    return times;
}

} // namespace

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_store(m_database)
{
}

bool AppController::initialize(const QString &databasePath, QString *error)
{
    QDir().mkpath(QFileInfo(databasePath).absolutePath());
    return m_database.open(databasePath, error);
}

QVariantList AppController::medications() const
{
    QVariantList list;
    const QList<Medication> meds = m_store.medications();
    for (const Medication &m : meds)
        list.append(medicationToMap(m));
    return list;
}

QVariantList AppController::regimens() const
{
    QVariantList list;
    const QList<Regimen> items = m_store.regimens();
    for (const Regimen &r : items)
        list.append(regimenToMap(r, m_store.medication(r.medicationId)));
    return list;
}

QVariantList AppController::todayDoses() const
{
    const QDate today = QDate::currentDate();
    const QDateTime now = QDateTime::currentDateTimeUtc();
    const QList<Intake> intakes = m_store.intakes();

    QVariantList list;
    const QList<Regimen> items = m_store.regimens(-1, true);
    for (const Regimen &r : items) {
        if (!ScheduleEngine::isDosingDay(r, today))
            continue;
        const Medication med = m_store.medication(r.medicationId);
        for (const QTime &time : r.times) {
            const QDateTime scheduled(today, time, Qt::LocalTime);
            if (!scheduled.isValid())
                continue;
            const QDateTime scheduledUtc = scheduled.toUTC();

            QVariantMap map = regimenToMap(r, med);
            map[QStringLiteral("regimenId")] = r.id;
            map[QStringLiteral("scheduledAt")] = scheduledUtc.toString(Qt::ISODate);
            map[QStringLiteral("time")] = time.toString(QStringLiteral("HH:mm"));

            QString status;
            qint64 intakeId = -1;
            for (const Intake &intake : intakes) {
                if (intake.regimenId == r.id && intake.scheduledAt.isValid()
                    && intake.scheduledAt.toUTC().toMSecsSinceEpoch() / 1000
                        == scheduledUtc.toMSecsSinceEpoch() / 1000) {
                    status = intake.status;
                    intakeId = intake.id;
                    break;
                }
            }
            if (status.isEmpty() && scheduledUtc < now)
                status = QStringLiteral("missed");

            map[QStringLiteral("status")] = status;
            map[QStringLiteral("intakeId")] = intakeId;
            list.append(map);
        }
    }

    std::sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("scheduledAt")).toString()
             < b.toMap().value(QStringLiteral("scheduledAt")).toString();
    });
    return list;
}

QVariantList AppController::history() const
{
    QVariantList list;
    const QList<Intake> intakes = m_store.intakes();
    for (const Intake &i : intakes) {
        const Medication m = m_store.medication(i.medicationId);
        QVariantMap map;
        map[QStringLiteral("id")] = i.id;
        map[QStringLiteral("medicationId")] = i.medicationId;
        map[QStringLiteral("medicationName")] = m.name;
        map[QStringLiteral("takenAt")] = i.takenAt.toLocalTime().toString(Qt::ISODate);
        map[QStringLiteral("amount")] = i.amount;
        map[QStringLiteral("unit")] = i.unit;
        map[QStringLiteral("status")] = i.status;
        map[QStringLiteral("notes")] = i.notes;
        list.append(map);
    }
    return list;
}

QString AppController::todayLabel() const
{
    return QDate::currentDate().toString(Qt::DefaultLocaleLongDate);
}

QVariantMap AppController::medication(int id) const
{
    return medicationToMap(m_store.medication(id));
}

QVariantMap AppController::regimen(int id) const
{
    const Regimen r = m_store.regimen(id);
    return regimenToMap(r, m_store.medication(r.medicationId));
}

bool AppController::saveMedication(const QVariantMap &data)
{
    Medication m;
    m.id = data.value(QStringLiteral("id"), -1).toLongLong();
    m.name = data.value(QStringLiteral("name")).toString().trimmed();
    m.form = data.value(QStringLiteral("form")).toString().trimmed();
    m.strength = data.value(QStringLiteral("strength")).toDouble();
    m.unit = data.value(QStringLiteral("unit")).toString().trimmed();
    m.notes = data.value(QStringLiteral("notes")).toString().trimmed();
    m.active = data.value(QStringLiteral("active"), true).toBool();
    if (m.name.isEmpty())
        return false;

    const bool ok = m.id >= 0 ? m_store.updateMedication(m) : m_store.addMedication(m);
    if (ok)
        emit changed();
    return ok;
}

bool AppController::removeMedication(int id)
{
    const bool ok = m_store.removeMedication(id);
    if (ok)
        emit changed();
    return ok;
}

bool AppController::saveRegimen(const QVariantMap &data)
{
    Regimen r;
    r.id = data.value(QStringLiteral("id"), -1).toLongLong();
    r.medicationId = data.value(QStringLiteral("medicationId"), -1).toLongLong();
    r.dose = data.value(QStringLiteral("dose")).toDouble();
    r.unit = data.value(QStringLiteral("unit")).toString().trimmed();
    r.route = data.value(QStringLiteral("route")).toString().trimmed();
    r.intervalDays = qMax(1, data.value(QStringLiteral("intervalDays"), 1).toInt());
    r.daysOfWeek = toDayList(data.value(QStringLiteral("daysOfWeek")).toList());
    r.times = toTimeList(data.value(QStringLiteral("times")).toList());
    r.startDate = QDate::fromString(data.value(QStringLiteral("startDate")).toString(), Qt::ISODate);
    const QString end = data.value(QStringLiteral("endDate")).toString();
    r.endDate = end.isEmpty() ? QDate() : QDate::fromString(end, Qt::ISODate);
    r.active = data.value(QStringLiteral("active"), true).toBool();

    if (r.medicationId < 0 || !r.startDate.isValid() || r.times.isEmpty())
        return false;

    const bool ok = r.id >= 0 ? m_store.updateRegimen(r) : m_store.addRegimen(r);
    if (ok)
        emit changed();
    return ok;
}

bool AppController::removeRegimen(int id)
{
    const bool ok = m_store.removeRegimen(id);
    if (ok)
        emit changed();
    return ok;
}

bool AppController::logDose(int regimenId, int medicationId,
                            const QString &scheduledAtIso, const QString &status)
{
    const QDateTime scheduled = QDateTime::fromString(scheduledAtIso, Qt::ISODate);
    const Regimen r = m_store.regimen(regimenId);
    const Medication med = m_store.medication(r.medicationId >= 0 ? r.medicationId : medicationId);

    // Update the existing log for this exact scheduled dose, if any.
    const QList<Intake> intakes = m_store.intakes(medicationId);
    for (const Intake &existing : intakes) {
        if (existing.regimenId == regimenId && existing.scheduledAt.isValid()
            && scheduled.isValid()
            && existing.scheduledAt.toUTC().toMSecsSinceEpoch() / 1000
                == scheduled.toUTC().toMSecsSinceEpoch() / 1000) {
            Intake updated = existing;
            updated.status = status;
            const bool ok = m_store.updateIntake(updated);
            if (ok)
                emit changed();
            return ok;
        }
    }

    Intake intake;
    intake.regimenId = regimenId;
    intake.medicationId = medicationId;
    intake.scheduledAt = scheduled;
    intake.takenAt = QDateTime::currentDateTimeUtc();
    intake.amount = med.strength;
    intake.unit = med.unit;
    intake.status = status;
    const bool ok = m_store.addIntake(intake);
    if (ok)
        emit changed();
    return ok;
}

bool AppController::clearIntake(int intakeId)
{
    return removeIntake(intakeId);
}

bool AppController::removeIntake(int intakeId)
{
    const bool ok = m_store.removeIntake(intakeId);
    if (ok)
        emit changed();
    return ok;
}

} // namespace dollfin
