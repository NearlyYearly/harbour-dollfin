// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#include "analytes.h"

#include <QCoreApplication>
#include <QHash>

#include <algorithm>

namespace dollfin {
namespace {

// QT_TRANSLATE_NOOP marks the literal for lupdate; the real translation happens
// in catalog(). A plain helper function would hide the strings from lupdate.

struct Raw {
    const char *key;
    const char *label;
    const char *unit;
    const char *reference;
};

struct Band {
    const char *key;
    double low;
    double high;
};

// Hormones and HRT monitoring first, then general health (D-024/D-025).
// References are general Dutch adult values and are shown neutrally; HRT
// hormones are descriptive only, never a target band (D-012).
const Raw kAnalytes[] = {
    // Hormones / HRT
    { "estradiol", QT_TRANSLATE_NOOP("Dollfin", "Estradiol (E2)"), "pmol/L", QT_TRANSLATE_NOOP("Dollfin", "Varies with cycle / menopause / HRT") },
    { "estrone", QT_TRANSLATE_NOOP("Dollfin", "Estrone (E1)"), "pmol/L", QT_TRANSLATE_NOOP("Dollfin", "Varies with context") },
    { "testosterone", QT_TRANSLATE_NOOP("Dollfin", "Testosterone (total)"), "nmol/L", QT_TRANSLATE_NOOP("Dollfin", "M 8-30 · F 0.5-2.5") },
    { "free_testosterone", QT_TRANSLATE_NOOP("Dollfin", "Testosterone (free)"), "pmol/L", QT_TRANSLATE_NOOP("Dollfin", "M 170-500 · F under 30") },
    { "prolactin", QT_TRANSLATE_NOOP("Dollfin", "Prolactin"), "µg/L", QT_TRANSLATE_NOOP("Dollfin", "M under 15 · F under 25") },
    { "lh", QT_TRANSLATE_NOOP("Dollfin", "LH"), "U/L", QT_TRANSLATE_NOOP("Dollfin", "Varies with cycle · M 1.5-9") },
    { "fsh", QT_TRANSLATE_NOOP("Dollfin", "FSH"), "U/L", QT_TRANSLATE_NOOP("Dollfin", "Varies with cycle · M 1.5-12") },
    { "shbg", QT_TRANSLATE_NOOP("Dollfin", "SHBG"), "nmol/L", QT_TRANSLATE_NOOP("Dollfin", "M 20-70 · F 40-120") },
    { "progesterone", QT_TRANSLATE_NOOP("Dollfin", "Progesterone"), "nmol/L", QT_TRANSLATE_NOOP("Dollfin", "M under 1 · F follicular under 3, luteal 15-80") },
    { "dhea_s", QT_TRANSLATE_NOOP("Dollfin", "DHEA-S"), "µmol/L", QT_TRANSLATE_NOOP("Dollfin", "Age-dependent; roughly 2-10") },
    { "cortisol", QT_TRANSLATE_NOOP("Dollfin", "Cortisol"), "nmol/L", QT_TRANSLATE_NOOP("Dollfin", "Morning 150-550 (diurnal)") },
    { "tsh", QT_TRANSLATE_NOOP("Dollfin", "TSH"), "mU/L", QT_TRANSLATE_NOOP("Dollfin", "0.4-4.0") },
    { "ft4", QT_TRANSLATE_NOOP("Dollfin", "Free T4"), "pmol/L", QT_TRANSLATE_NOOP("Dollfin", "8-22") },
    { "ft3", QT_TRANSLATE_NOOP("Dollfin", "Free T3"), "pmol/L", QT_TRANSLATE_NOOP("Dollfin", "3.5-6.5") },

    // Liver / kidney / blood count / lipids / the alike
    { "alt", QT_TRANSLATE_NOOP("Dollfin", "ALT (ALAT)"), "U/L", QT_TRANSLATE_NOOP("Dollfin", "M under 40 · F under 30") },
    { "ast", QT_TRANSLATE_NOOP("Dollfin", "AST (ASAT)"), "U/L", QT_TRANSLATE_NOOP("Dollfin", "M under 35 · F under 30") },
    { "ggt", QT_TRANSLATE_NOOP("Dollfin", "GGT (gamma-GT)"), "U/L", QT_TRANSLATE_NOOP("Dollfin", "M under 55 · F under 40") },
    { "alp", QT_TRANSLATE_NOOP("Dollfin", "ALP (alkaline phosphatase)"), "U/L", QT_TRANSLATE_NOOP("Dollfin", "40-120") },
    { "bilirubin", QT_TRANSLATE_NOOP("Dollfin", "Bilirubin (total)"), "µmol/L", QT_TRANSLATE_NOOP("Dollfin", "under 17") },
    { "albumin", QT_TRANSLATE_NOOP("Dollfin", "Albumin"), "g/L", QT_TRANSLATE_NOOP("Dollfin", "35-50") },
    { "creatinine", QT_TRANSLATE_NOOP("Dollfin", "Creatinine"), "µmol/L", QT_TRANSLATE_NOOP("Dollfin", "M 65-115 · F 50-95") },
    { "egfr", QT_TRANSLATE_NOOP("Dollfin", "eGFR"), "mL/min/1.73 m²", QT_TRANSLATE_NOOP("Dollfin", "above 90") },
    { "hemoglobin", QT_TRANSLATE_NOOP("Dollfin", "Hemoglobin"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "M 8.5-10.5 · F 7.5-10.0") },
    { "hematocrit", QT_TRANSLATE_NOOP("Dollfin", "Hematocrit"), "L/L", QT_TRANSLATE_NOOP("Dollfin", "M 0.40-0.50 · F 0.35-0.45") },
    { "ferritin", QT_TRANSLATE_NOOP("Dollfin", "Ferritin"), "µg/L", QT_TRANSLATE_NOOP("Dollfin", "M 30-300 · F 15-200") },
    { "ldl", QT_TRANSLATE_NOOP("Dollfin", "LDL cholesterol"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "under 3.0") },
    { "hdl", QT_TRANSLATE_NOOP("Dollfin", "HDL cholesterol"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "M above 1.0 · F above 1.2") },
    { "triglycerides", QT_TRANSLATE_NOOP("Dollfin", "Triglycerides"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "under 2.0") },
    { "glucose", QT_TRANSLATE_NOOP("Dollfin", "Glucose (fasting)"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "4.0-6.0") },
    { "hba1c", QT_TRANSLATE_NOOP("Dollfin", "HbA1c"), "mmol/mol", QT_TRANSLATE_NOOP("Dollfin", "20-42") },
    { "sodium", QT_TRANSLATE_NOOP("Dollfin", "Sodium"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "135-145") },
    { "potassium", QT_TRANSLATE_NOOP("Dollfin", "Potassium"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "3.5-5.0") },
    { "calcium", QT_TRANSLATE_NOOP("Dollfin", "Calcium (total)"), "mmol/L", QT_TRANSLATE_NOOP("Dollfin", "2.20-2.60") },
    { "vitamin_d", QT_TRANSLATE_NOOP("Dollfin", "Vitamin D (25-OH)"), "nmol/L", QT_TRANSLATE_NOOP("Dollfin", "50-150") },
    { "vitamin_b12", QT_TRANSLATE_NOOP("Dollfin", "Vitamin B12"), "pmol/L", QT_TRANSLATE_NOOP("Dollfin", "150-600") },
};

// Graph bands, only where the range is a clear two-sided value in the catalogue
// unit (D-029). Sex-specific, one-sided and context-dependent ranges get none.
const Band kBands[] = {
    { "tsh", 0.4, 4.0 },
    { "ft4", 8.0, 22.0 },
    { "ft3", 3.5, 6.5 },
    { "alp", 40.0, 120.0 },
    { "albumin", 35.0, 50.0 },
    { "glucose", 4.0, 6.0 },
    { "hba1c", 20.0, 42.0 },
    { "sodium", 135.0, 145.0 },
    { "potassium", 3.5, 5.0 },
    { "calcium", 2.20, 2.60 },
    { "vitamin_d", 50.0, 150.0 },
    { "vitamin_b12", 150.0, 600.0 },
};

} // namespace

QList<AnalyteRef> Analytes::catalog()
{
    QList<AnalyteRef> list;
    const int count = int(sizeof(kAnalytes) / sizeof(kAnalytes[0]));
    for (int i = 0; i < count; ++i) {
        const Raw &raw = kAnalytes[i];
        AnalyteRef analyte;
        analyte.key = QString::fromLatin1(raw.key);
        analyte.label = QCoreApplication::translate("Dollfin", raw.label);
        analyte.unit = QString::fromUtf8(raw.unit);
        analyte.reference = QCoreApplication::translate("Dollfin", raw.reference);
        for (const Band &band : kBands) {
            if (analyte.key == QLatin1String(band.key)) {
                analyte.hasBand = true;
                analyte.bandLow = band.low;
                analyte.bandHigh = band.high;
                break;
            }
        }
        list.append(analyte);
    }
    return list;
}

// Units are stored data, not UI text, so they stay canonical (D-022/D-024).
QStringList Analytes::units()
{
    static const QStringList units = QStringList()
        << QStringLiteral("pmol/L") << QStringLiteral("nmol/L") << QStringLiteral("µmol/L")
        << QStringLiteral("mmol/L") << QStringLiteral("mmol/mol") << QStringLiteral("U/L")
        << QStringLiteral("mU/L") << QStringLiteral("µg/L") << QStringLiteral("ng/mL")
        << QStringLiteral("pg/mL") << QStringLiteral("mg/dL") << QStringLiteral("ng/dL")
        << QStringLiteral("µg/dL") << QStringLiteral("g/L") << QStringLiteral("g/dL")
        << QStringLiteral("mg/L") << QStringLiteral("mL/min/1.73 m²") << QStringLiteral("mL/min")
        << QStringLiteral("%") << QStringLiteral("L/L") << QStringLiteral("10⁹/L")
        << QStringLiteral("10¹²/L") << QStringLiteral("fL") << QStringLiteral("pg")
        << QStringLiteral("mEq/L") << QStringLiteral("IU/L") << QStringLiteral("U/mL")
        << QStringLiteral("ratio");
    return units;
}

const AnalyteRef *Analytes::find(const QString &key)
{
    // Built once; translations are installed before the UI (D-014).
    static const QList<AnalyteRef> cache = catalog();
    for (const AnalyteRef &analyte : cache) {
        if (analyte.key == key)
            return &analyte;
    }
    return nullptr;
}

QString Analytes::label(const QString &key)
{
    if (const AnalyteRef *analyte = find(key))
        return analyte->label;
    return key;
}

QList<AnalyteSummary> Analytes::summarize(const QList<Level> &levels)
{
    QList<AnalyteSummary> list;
    QHash<QString, int> position;
    QHash<QString, QDateTime> newest;

    for (const Level &level : levels) {
        const QString key = level.analyte;
        const int pos = position.value(key, -1);
        if (pos < 0) {
            const AnalyteRef *ref = find(key);
            AnalyteSummary summary;
            summary.key = key;
            summary.label = ref ? ref->label : key;
            summary.unit = level.unit;
            summary.referenceUnit = ref ? ref->unit : QString();
            summary.reference = ref ? ref->reference : QString();
            summary.value = level.value;
            summary.date = level.takenAt.toLocalTime().date();
            summary.count = 1;
            summary.custom = ref == nullptr;
            if (ref) {
                summary.hasBand = ref->hasBand;
                summary.bandLow = ref->bandLow;
                summary.bandHigh = ref->bandHigh;
            }
            position.insert(key, list.size());
            newest.insert(key, level.takenAt);
            list.append(summary);
        } else {
            list[pos].count += 1;
            if (level.takenAt > newest.value(key)) {
                newest[key] = level.takenAt;
                list[pos].value = level.value;
                list[pos].unit = level.unit;
                list[pos].date = level.takenAt.toLocalTime().date();
            }
        }
    }

    std::stable_sort(list.begin(), list.end(), [](const AnalyteSummary &a, const AnalyteSummary &b) {
        return a.date > b.date;
    });
    return list;
}

} // namespace dollfin
