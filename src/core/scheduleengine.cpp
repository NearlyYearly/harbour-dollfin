// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#include "scheduleengine.h"

#include <algorithm>

namespace dollfin {

bool ScheduleEngine::isDosingDay(const Regimen &regimen, const QDate &date)
{
    if (!date.isValid() || !regimen.startDate.isValid() || date < regimen.startDate)
        return false;
    if (regimen.endDate.isValid() && date > regimen.endDate)
        return false;

    if (!regimen.daysOfWeek.isEmpty())
        return regimen.daysOfWeek.contains(date.dayOfWeek());

    const int interval = qMax(1, regimen.intervalDays);
    if (interval == 1)
        return true;
    return regimen.startDate.daysTo(date) % interval == 0;
}

QList<QDateTime> ScheduleEngine::occurrences(const Regimen &regimen,
                                             const QDateTime &fromUtc,
                                             const QDateTime &toUtc)
{
    QList<QDateTime> result;
    if (!regimen.active || regimen.times.isEmpty() || !regimen.startDate.isValid())
        return result;

    const QDate fromDate = fromUtc.toLocalTime().date().addDays(-1);
    QDate date = fromDate < regimen.startDate ? regimen.startDate : fromDate;
    const QDate lastDate = toUtc.toLocalTime().date().addDays(1);
    const QDate end = (regimen.endDate.isValid() && regimen.endDate < lastDate) ? regimen.endDate : lastDate;

    for (; date <= end; date = date.addDays(1)) {
        if (!isDosingDay(regimen, date))
            continue;
        for (const QTime &time : regimen.times) {
            const QDateTime local(date, time, Qt::LocalTime);
            if (!local.isValid())
                continue;
            const QDateTime utc = local.toUTC();
            if (utc >= fromUtc && utc < toUtc)
                result.append(utc);
        }
    }

    std::sort(result.begin(), result.end());
    return result;
}

QDateTime ScheduleEngine::firstOccurrenceAfter(const Regimen &regimen, const QDateTime &afterUtc)
{
    if (!regimen.active || regimen.times.isEmpty() || !regimen.startDate.isValid())
        return QDateTime();

    // Bounded scan (a year) so a broken regimen can never loop forever.
    const QDateTime horizon = afterUtc.addDays(366);
    const QList<QDateTime> found = occurrences(regimen, afterUtc.addMSecs(1), horizon);
    return found.isEmpty() ? QDateTime() : found.first();
}

} // namespace dollfin
