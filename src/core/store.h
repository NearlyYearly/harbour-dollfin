// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#pragma once

#include "types.h"

#include <QList>
#include <QString>

namespace dollfin {

class Database;

// Thin CRUD layer over the SQLite schema. No business logic lives here.
class Store
{
public:
    explicit Store(Database &database);

    // Medications ------------------------------------------------------------
    bool addMedication(Medication &medication, QString *error = nullptr);
    bool updateMedication(const Medication &medication, QString *error = nullptr);
    bool removeMedication(qint64 id, QString *error = nullptr);
    Medication medication(qint64 id, bool *ok = nullptr) const;
    QList<Medication> medications(bool onlyActive = false) const;

    // Regimens ---------------------------------------------------------------
    bool addRegimen(Regimen &regimen, QString *error = nullptr);
    bool updateRegimen(const Regimen &regimen, QString *error = nullptr);
    bool removeRegimen(qint64 id, QString *error = nullptr);
    Regimen regimen(qint64 id, bool *ok = nullptr) const;
    QList<Regimen> regimens(qint64 medicationId = -1, bool onlyActive = false) const;

    // Intakes ----------------------------------------------------------------
    bool addIntake(Intake &intake, QString *error = nullptr);
    bool updateIntake(const Intake &intake, QString *error = nullptr);
    bool removeIntake(qint64 id, QString *error = nullptr);
    QList<Intake> intakes(qint64 medicationId = -1) const;

    // Stock ------------------------------------------------------------------
    bool setStock(const Stock &stock, QString *error = nullptr);
    Stock stock(qint64 medicationId, bool *ok = nullptr) const;

    // Levels -----------------------------------------------------------------
    bool addLevel(Level &level, QString *error = nullptr);
    QList<Level> levels() const;

private:
    Database &m_database;
};

} // namespace dollfin
