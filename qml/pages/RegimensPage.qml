// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int medicationId: -1
    property string medicationName: ""

    function regimensForMedication() {
        var all = app.regimens
        var out = []
        for (var i = 0; i < all.length; ++i) {
            if (all[i].medicationId === medicationId)
                out.push(all[i])
        }
        return out
    }

    function scheduleLabel(regimen) {
        var when
        if (regimen.daysOfWeek.length > 0)
            when = qsTr("Weekly")
        else if (regimen.intervalDays > 1)
            when = qsTr("Every %1 days").arg(regimen.intervalDays)
        else
            when = qsTr("Daily")
        return when + " · " + regimen.timesText
    }

    Component.onCompleted: medicationName = app.medication(medicationId).name

    SilicaListView {
        id: list
        anchors.fill: parent
        model: page.regimensForMedication()
        header: PageHeader { title: page.medicationName }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add schedule")
                onClicked: pageStack.push(Qt.resolvedUrl("RegimenEditPage.qml"),
                                          { medicationId: page.medicationId })
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: qsTr("No schedule")
            hintText: qsTr("Pull down to add one")
        }

        delegate: ListItem {
            id: delegate
            contentHeight: Theme.itemSizeMedium

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.push(Qt.resolvedUrl("RegimenEditPage.qml"),
                                              { medicationId: page.medicationId, regimenId: modelData.id })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: Remorse.itemAction(delegate, qsTr("Deleting"),
                                               function() { app.removeRegimen(modelData.id) })
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("RegimenEditPage.qml"),
                                      { medicationId: page.medicationId, regimenId: modelData.id })

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: modelData.doseText.length > 0 ? modelData.doseText : qsTr("Dose")
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    width: parent.width
                    text: page.scheduleLabel(modelData)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        VerticalScrollDecorator {}
    }

}
