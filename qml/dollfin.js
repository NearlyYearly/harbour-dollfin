// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje
//
// Shared helpers for the QML pages. No translated strings here (qsTr is not
// available in plain .js); pass labels in from QML.

function statusSymbol(status) {
    if (status === "taken")
        return "\u2705"   // check mark button
    if (status === "skipped")
        return "\u23ED"   // next track
    if (status === "missed")
        return "\u26A0"   // warning
    return "\u25CB"       // white circle (due)
}
