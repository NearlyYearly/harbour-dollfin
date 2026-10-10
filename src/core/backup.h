// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#pragma once

#include <QString>

namespace dollfin {

class Database;

// Full JSON export/import of every table. The dump is generic (all columns of
// each table), so it keeps working as the schema grows.
class Backup
{
public:
    static QString toJson(const Database &database);
    static bool fromJson(Database &database, const QString &json, QString *error = nullptr);
};

} // namespace dollfin
