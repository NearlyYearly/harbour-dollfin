// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#include "ical.h"

#include <QDateTime>
#include <QStringList>

namespace dollfin {
namespace {

// iCalendar wants CRLF line endings.
const char *kCrLf = "\r\n";

QString rruleFor(const Regimen &regimen)
{
    if (!regimen.daysOfWeek.isEmpty()) {
        static const char *names[] = { "MO", "TU", "WE", "TH", "FR", "SA", "SU" };
        QStringList byday;
        for (int day : regimen.daysOfWeek) {
            if (day >= 1 && day <= 7)
                byday.append(QString::fromLatin1(names[day - 1]));
        }
        if (!byday.isEmpty())
            return QStringLiteral("FREQ=WEEKLY;BYDAY=") + byday.join(QLatin1Char(','));
    }
    if (regimen.intervalDays > 1)
        return QStringLiteral("FREQ=DAILY;INTERVAL=") + QString::number(regimen.intervalDays);
    return QStringLiteral("FREQ=DAILY");
}

// First date on/after startDate that the regimen actually doses.
QDate firstDosingDate(const Regimen &regimen)
{
    QDate date = regimen.startDate;
    if (!regimen.daysOfWeek.isEmpty()) {
        for (int i = 0; i < 7 && !regimen.daysOfWeek.contains(date.dayOfWeek()); ++i)
            date = date.addDays(1);
    }
    return date;
}

QString stamp()
{
    return QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyyMMddTHHmmssZ"));
}

} // namespace

QString ICal::event(const Regimen &regimen, const QString &summary, const QTime &time)
{
    const QDateTime start(firstDosingDate(regimen), time, Qt::LocalTime);
    const QString uid = QStringLiteral("dollfin-%1-%2@dollfin")
                            .arg(regimen.id)
                            .arg(time.toString(QStringLiteral("HHmm")));

    QString event;
    event += QLatin1String("BEGIN:VEVENT") + QLatin1String(kCrLf);
    event += QLatin1String("UID:") + uid + QLatin1String(kCrLf);
    event += QLatin1String("DTSTAMP:") + stamp() + QLatin1String(kCrLf);
    event += QLatin1String("DTSTART:") + start.toString(QStringLiteral("yyyyMMddTHHmmss"))
             + QLatin1String(kCrLf);
    event += QLatin1String("DURATION:PT1M") + QLatin1String(kCrLf); // 1-minute event (D-021)
    event += QLatin1String("RRULE:") + rruleFor(regimen) + QLatin1String(kCrLf);
    event += QLatin1String("SUMMARY:") + summary + QLatin1String(kCrLf);
    event += QLatin1String("DESCRIPTION:Open Dollfin to log this dose.") + QLatin1String(kCrLf);
    event += QLatin1String("BEGIN:VALARM") + QLatin1String(kCrLf);
    event += QLatin1String("ACTION:DISPLAY") + QLatin1String(kCrLf);
    event += QLatin1String("DESCRIPTION:") + summary + QLatin1String(kCrLf);
    event += QLatin1String("TRIGGER:PT0S") + QLatin1String(kCrLf); // alarm at event start
    event += QLatin1String("END:VALARM") + QLatin1String(kCrLf);
    event += QLatin1String("END:VEVENT") + QLatin1String(kCrLf);
    return event;
}

QString ICal::wrap(const QStringList &events)
{
    QString calendar;
    calendar += QLatin1String("BEGIN:VCALENDAR") + QLatin1String(kCrLf);
    calendar += QLatin1String("VERSION:2.0") + QLatin1String(kCrLf);
    calendar += QLatin1String("PRODID:-//dollfin//dollfin//EN") + QLatin1String(kCrLf);
    calendar += QLatin1String("CALSCALE:GREGORIAN") + QLatin1String(kCrLf);
    for (const QString &event : events)
        calendar += event;
    calendar += QLatin1String("END:VCALENDAR") + QLatin1String(kCrLf);
    return calendar;
}

} // namespace dollfin
