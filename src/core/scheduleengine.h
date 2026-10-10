// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#pragma once

#include "types.h"

#include <QDateTime>
#include <QList>

namespace dollfin {

// Pure schedule expansion. No database, no UI.
//
// A regimen is either:
//   - weekly on `daysOfWeek` (1=Mon .. 7=Sun), or
//   - every `intervalDays` days anchored at `startDate` (1 = daily).
// Each matching day produces one occurrence per entry in `times` (local time).
class ScheduleEngine
{
public:
    // Occurrences in [fromUtc, toUtc), returned in UTC and sorted.
    static QList<QDateTime> occurrences(const Regimen &regimen,
                                        const QDateTime &fromUtc,
                                        const QDateTime &toUtc);

    // First occurrence strictly after `afterUtc`, or an invalid QDateTime.
    static QDateTime firstOccurrenceAfter(const Regimen &regimen, const QDateTime &afterUtc);

    // True if `date` (local) is a dosing day for this regimen.
    static bool isDosingDay(const Regimen &regimen, const QDate &date);
};

} // namespace dollfin
