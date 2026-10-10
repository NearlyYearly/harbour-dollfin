// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

// One row per analyte the user has results for (derived, D-028). Tapping opens
// that analyte's results; the analyte is fixed there.
Page {
    id: page

    function when(iso) {
        var d = new Date(iso + "T00:00:00")
        if (isNaN(d.getTime()))
            return iso
        return Qt.formatDate(d, "d MMM yyyy")
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: app.analyteSummaries
        header: PageHeader { title: qsTr("Labs") }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add result")
                onClicked: pageStack.push(Qt.resolvedUrl("LabEditPage.qml"))
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: qsTr("No results yet")
            hintText: qsTr("Pull down to add a blood test result")
        }

        delegate: ListItem {
            id: delegate
            contentHeight: Theme.itemSizeMedium

            onClicked: pageStack.push(Qt.resolvedUrl("AnalyteResultsPage.qml"),
                                      { summary: modelData })

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: modelData.label
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    width: parent.width
                    text: modelData.value + " " + modelData.unit + " · " + page.when(modelData.date)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
