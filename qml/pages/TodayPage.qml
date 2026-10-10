// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../dollfin.js" as Dollfin

Page {
    id: page

    SilicaListView {
        id: list
        anchors.fill: parent
        model: app.todayDoses

        header: Column {
            width: list.width
            PageHeader { title: qsTr("Today") }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: app.todayLabel
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Item { width: 1; height: Theme.paddingMedium }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Medications")
                onClicked: pageStack.push(Qt.resolvedUrl("MedicationsPage.qml"))
            }
            MenuItem {
                text: qsTr("History")
                onClicked: pageStack.push(Qt.resolvedUrl("HistoryPage.qml"))
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: qsTr("Nothing scheduled")
            hintText: qsTr("Pull down to add a medication")
        }

        delegate: ListItem {
            id: delegate
            contentHeight: Theme.itemSizeMedium
            width: list.width

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Mark taken")
                    visible: modelData.status !== "taken"
                    onClicked: app.logDose(modelData.regimenId, modelData.medicationId, modelData.scheduledAt, "taken")
                }
                MenuItem {
                    text: qsTr("Mark skipped")
                    visible: modelData.status !== "skipped"
                    onClicked: app.logDose(modelData.regimenId, modelData.medicationId, modelData.scheduledAt, "skipped")
                }
                MenuItem {
                    text: qsTr("Undo")
                    visible: modelData.status === "taken" || modelData.status === "skipped"
                    onClicked: app.removeIntake(modelData.intakeId)
                }
            }

            onClicked: {
                if (modelData.status === "taken")
                    app.removeIntake(modelData.intakeId)
                else
                    app.logDose(modelData.regimenId, modelData.medicationId, modelData.scheduledAt, "taken")
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium

                Label {
                    text: modelData.time
                    width: Theme.itemSizeSmall
                    color: modelData.status === "missed" ? Theme.secondaryHighlightColor : Theme.highlightColor
                }

                Column {
                    width: parent.width - Theme.itemSizeSmall - Theme.itemSizeSmall - 2 * Theme.paddingMedium
                    Label {
                        width: parent.width
                        text: modelData.medicationName
                        color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.width
                        text: modelData.doseText
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
                    }
                }

                Label {
                    text: Dollfin.statusSymbol(modelData.status)
                    font.pixelSize: Theme.fontSizeLarge
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
