// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#pragma once

#include "types.h"

#include <QDate>
#include <QList>
#include <QString>
#include <QStringList>

namespace dollfin {

// A known analyte: the stable key stored in level.analyte, the translated
// display label, the canonical unit, and a general adult reference range
// (Dutch standards, D-025). Empty reference => show none (custom analytes).
struct AnalyteRef {
    QString key;
    QString label;
    QString unit;
    QString reference;
    // Numeric band for the graph, set only for unambiguous two-sided ranges
    // (D-029). Sex-specific / one-sided / context-dependent ranges have none.
    bool hasBand = false;
    double bandLow = 0.0;
    double bandHigh = 0.0;
};

// One row on the Labs page: the most recent result for an analyte and how many
// results it has (D-028). Grouping is derived from the level rows, no new table.
struct AnalyteSummary {
    QString key;
    QString label;
    QString unit;          // unit of the most recent result
    QString referenceUnit; // catalogue unit the reference applies to ("" = custom)
    QString reference;     // catalogue reference text ("" = custom)
    double value = 0.0;    // most recent value
    QDate date;            // most recent draw date
    int count = 0;
    bool custom = false;
    bool hasBand = false;
    double bandLow = 0.0;
    double bandHigh = 0.0;
};

namespace Analytes {

// HRT and hormones first, then general monitoring (liver, kidney, blood count,
// lipids, ...). Labels/references are translated per call.
QList<AnalyteRef> catalog();

// Fixed unit drop-down (D-024); never free text.
QStringList units();

// The catalog entry for a key, or nullptr for a custom analyte.
const AnalyteRef *find(const QString &key);

// Display label for a stored analyte value: the catalog label, or the stored
// text itself when it is a custom analyte.
QString label(const QString &key);

// Group level rows into one summary per analyte, most recent first (D-028).
// Input order does not matter: the newest taken_at wins.
QList<AnalyteSummary> summarize(const QList<Level> &levels);

} // namespace Analytes

} // namespace dollfin
