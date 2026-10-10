// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#pragma once

#include "core/database.h"
#include "core/store.h"

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

namespace dollfin {

// The single object exposed to QML as `app`. Owns the database and turns the
// core structs into plain QVariantMaps/lists. Lists are rebuilt and re-emitted
// on every change (the data set is tiny, so this stays simple and reactive).
class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList medications READ medications NOTIFY changed)
    Q_PROPERTY(QVariantList regimens READ regimens NOTIFY changed)
    Q_PROPERTY(QVariantList todayDoses READ todayDoses NOTIFY changed)
    Q_PROPERTY(QVariantList history READ history NOTIFY changed)
    Q_PROPERTY(QString todayLabel READ todayLabel NOTIFY changed)
    Q_PROPERTY(int pendingDoses READ pendingDoses NOTIFY changed)

public:
    explicit AppController(QObject *parent = nullptr);

    bool initialize(const QString &databasePath, QString *error = nullptr);

    QVariantList medications() const;
    QVariantList regimens() const;
    QVariantList todayDoses() const;
    QVariantList history() const;
    QString todayLabel() const;
    int pendingDoses() const;

    Q_INVOKABLE QVariantMap medication(int id) const;
    Q_INVOKABLE QVariantMap regimen(int id) const;

    Q_INVOKABLE bool saveMedication(const QVariantMap &data);
    Q_INVOKABLE bool removeMedication(int id);
    Q_INVOKABLE bool saveRegimen(const QVariantMap &data);
    Q_INVOKABLE bool removeRegimen(int id);

    // status is "taken" or "skipped"; re-logging the same dose updates it.
    Q_INVOKABLE bool logDose(int regimenId, int medicationId,
                             const QString &scheduledAtIso, const QString &status);
    Q_INVOKABLE bool clearIntake(int intakeId);
    Q_INVOKABLE bool removeIntake(int intakeId);

    // Marks the first not-yet-logged dose of today as taken (cover quick action).
    Q_INVOKABLE bool logNextDoseTaken();

signals:
    void changed();

private:
    Database m_database;
    Store m_store;
};

} // namespace dollfin
