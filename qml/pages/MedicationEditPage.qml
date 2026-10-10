// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int medicationId: -1

    allowedOrientations: Orientation.All

    function save() {
        var data = {
            "id": medicationId,
            "name": nameField.text,
            "form": formField.text,
            "strength": parseFloat(strengthField.text) || 0,
            "unit": unitField.text,
            "notes": notesField.text,
            "active": true
        }
        if (app.saveMedication(data)) {
            pageStack.pop()
        } else {
            nameField.errorHighlight = true
            nameField.placeholderText = qsTr("A name is required")
        }
    }

    Component.onCompleted: {
        if (medicationId >= 0) {
            var m = app.medication(medicationId)
            nameField.text = m.name
            formField.text = m.form
            strengthField.text = m.strength > 0 ? String(m.strength) : ""
            unitField.text = m.unit
            notesField.text = m.notes
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Save"); onClicked: page.save() }
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: medicationId >= 0 ? qsTr("Edit medication") : qsTr("New medication")
            }

            TextField {
                id: nameField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Name")
                placeholderText: qsTr("Any medication you take")
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: page.save()
            }

            TextField {
                id: formField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Form")
                placeholderText: qsTr("tablet, gel, patch, injection…")
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                TextField {
                    id: strengthField
                    width: parent.width * 0.5
                    label: qsTr("Strength")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {}
                }

                TextField {
                    id: unitField
                    width: parent.width * 0.5 - Theme.paddingMedium
                    label: qsTr("Unit")
                    placeholderText: qsTr("mg")
                }
            }

            TextArea {
                id: notesField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Notes")
                placeholderText: qsTr("Optional")
            }
        }
    }
}
