// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#pragma once

#include "types.h"

#include <QString>
#include <QTime>

namespace dollfin {

// Builds the iCalendar handed to the Calendar UI (com.jolla.calendar.ui
// importIcsData) and to .ics file export (D-019).
class ICal
{
public:
    // One VEVENT for a single dose time of a regimen. `summary` is what the
    // user sees (the medication name). Local time, no timezone.
    static QString event(const Regimen &regimen, const QString &summary, const QTime &time);

    // Wraps VEVENT blocks into a VCALENDAR.
    static QString wrap(const QStringList &events);
};

} // namespace dollfin
