// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../dollfin.js" as Dollfin

Page {
    id: page

    function when(iso) {
        var d = new Date(iso)
        if (isNaN(d.getTime()))
            return iso
        return Qt.formatDateTime(d, "d MMM yyyy HH:mm")
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: app.history
        header: PageHeader { title: qsTr("History") }

        ViewPlaceholder {
            enabled: list.count === 0
            text: qsTr("Nothing logged yet")
            hintText: qsTr("Doses you tick off appear here")
        }

        delegate: ListItem {
            id: delegate
            contentHeight: Theme.itemSizeMedium

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: Remorse.itemAction(delegate, qsTr("Deleting"),
                                               function() { app.removeIntake(modelData.id) })
                }
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium

                Column {
                    width: parent.width - Theme.fontSizeLarge
                    Label {
                        width: parent.width
                        text: modelData.medicationName
                        color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.width
                        text: page.when(modelData.takenAt)
                             + (modelData.status === "skipped" ? " · " + qsTr("skipped") : "")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }

                Label {
                    text: Dollfin.statusSymbol(modelData.status)
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        VerticalScrollDecorator {}
    }

}
