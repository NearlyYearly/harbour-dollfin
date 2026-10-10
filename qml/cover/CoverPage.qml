// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../dollfin.js" as Dollfin

CoverBackground {
    id: cover

    Column {
        anchors.fill: parent
        anchors.margins: Theme.paddingMedium
        spacing: Theme.paddingSmall

        Label {
            width: parent.width
            text: qsTr("Today")
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        Repeater {
            model: app.todayDoses
            Row {
                width: parent.width
                Label {
                    width: parent.width - Theme.fontSizeLarge
                    text: modelData.time + "  " + modelData.medicationName
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    elide: Text.ElideRight
                }
                Label {
                    text: Dollfin.statusSymbol(modelData.status)
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
        }

        Label {
            visible: app.todayDoses.length === 0
            width: parent.width
            text: qsTr("No doses today")
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }
}
