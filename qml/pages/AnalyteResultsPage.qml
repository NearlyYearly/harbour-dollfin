// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

// Results for one analyte. New results are locked to this test so they cannot
// land under the wrong one.
Page {
    id: page

    property var summary

    property var results: {
        var all = app.labs
        var out = []
        var key = summary ? summary.key : ""
        for (var i = 0; i < all.length; ++i) {
            if (all[i].analyteKey === key)
                out.push(all[i])
        }
        return out
    }

    function when(iso) {
        var d = new Date(iso + "T00:00:00")
        if (isNaN(d.getTime()))
            return iso
        return Qt.formatDate(d, "d MMM yyyy")
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: page.results

        header: Column {
            width: list.width
            PageHeader { title: page.summary ? page.summary.label : "" }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                visible: page.summary && page.summary.reference.length > 0

                Label {
                    width: parent.width
                    text: qsTr("Reference (%1): %2")
                              .arg(page.summary ? page.summary.referenceUnit : "")
                              .arg(page.summary ? page.summary.reference : "")
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }

                Label {
                    width: parent.width
                    text: qsTr("Ranges vary by lab and are shown for reference only.")
                    wrapMode: Text.WordWrap
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }

                Item { width: 1; height: Theme.paddingSmall }
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add result")
                onClicked: pageStack.push(Qt.resolvedUrl("LabEditPage.qml"),
                                          { presetAnalyte: page.summary.key,
                                            lockAnalyte: true })
            }
            MenuItem {
                text: qsTr("Graph")
                onClicked: pageStack.push(Qt.resolvedUrl("AnalyteGraphPage.qml"),
                                          { summary: page.summary })
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: qsTr("No results yet")
            hintText: qsTr("Pull down to add one")
        }

        delegate: ListItem {
            id: delegate
            contentHeight: Theme.itemSizeMedium

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.push(Qt.resolvedUrl("LabEditPage.qml"),
                                              { labId: modelData.id })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: Remorse.itemAction(delegate, qsTr("Deleting"),
                                               function() { app.removeLab(modelData.id) })
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("LabEditPage.qml"),
                                      { labId: modelData.id })

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: modelData.value + " " + modelData.unit
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    width: parent.width
                    text: page.when(modelData.takenAt)
                          + (modelData.lab.length > 0 ? " · " + modelData.lab : "")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
