// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int labId: -1
    // When adding from an analyte's page: pre-set it and hide the picker (D-028).
    property string presetAnalyte: ""
    property bool lockAnalyte: false
    property var catalog: app.analyteCatalog()
    property var units: app.labUnits()
    property var drawDate: new Date()
    property string referenceText: ""

    // Index 0 is always "Custom": pick it to type any analyte (D-024).
    property var names: {
        var out = [qsTr("Custom")]
        for (var i = 0; i < catalog.length; ++i)
            out.push(catalog[i].label)
        return out
    }

    allowedOrientations: Orientation.All

    function isCustom() {
        return analyteCombo.currentIndex === 0
    }

    function currentKey() {
        if (isCustom())
            return customField.text.trim()
        return page.catalog[analyteCombo.currentIndex - 1].key
    }

    // Picking a catalog analyte defaults the unit to its usual one and shows the
    // reference; the unit stays selectable for labs that report differently.
    function applyAnalyte() {
        if (isCustom()) {
            customField.visible = true
            referenceText = ""
            return
        }
        customField.visible = false
        var entry = page.catalog[analyteCombo.currentIndex - 1]
        var index = page.units.indexOf(entry.unit)
        unitCombo.currentIndex = index >= 0 ? index : 0
        referenceText = entry.reference.length > 0
            ? qsTr("Reference (%1): %2").arg(entry.unit).arg(entry.reference) : ""
    }

    function lockedLabel() {
        if (analyteCombo.currentIndex > 0)
            return page.catalog[analyteCombo.currentIndex - 1].label
        return customField.text
    }

    function applyPreset() {
        var index = -1
        for (var i = 0; i < page.catalog.length; ++i) {
            if (page.catalog[i].key === page.presetAnalyte) {
                index = i + 1
                break
            }
        }
        if (index >= 0) {
            analyteCombo.currentIndex = index
        } else {
            analyteCombo.currentIndex = 0
            customField.text = page.presetAnalyte
        }
        page.applyAnalyte()
    }

    function save() {
        var key = currentKey()
        if (key.length === 0) {
            customField.errorHighlight = true
            return
        }
        var ok = app.saveLab({
            "id": labId,
            "analyteKey": key,
            "value": parseFloat(valueField.text) || 0,
            "unit": page.units[unitCombo.currentIndex],
            "takenAt": Qt.formatDate(drawDate, "yyyy-MM-dd"),
            "lab": labField.text,
            "notes": notesField.text
        })
        if (ok)
            pageStack.pop()
    }

    Component.onCompleted: {
        if (labId < 0) {
            if (presetAnalyte.length > 0)
                page.applyPreset()
            return
        }
        var l = app.lab(labId)
        var index = -1
        if (!l.custom) {
            for (var i = 0; i < page.catalog.length; ++i) {
                if (page.catalog[i].key === l.analyteKey) {
                    index = i + 1
                    break
                }
            }
        }
        if (index >= 0) {
            analyteCombo.currentIndex = index
        } else {
            analyteCombo.currentIndex = 0
            customField.text = l.analyteKey
        }
        valueField.text = String(l.value)
        var unitIndex = page.units.indexOf(l.unit)
        unitCombo.currentIndex = unitIndex >= 0 ? unitIndex : 0
        labField.text = l.lab
        notesField.text = l.notes
        if (l.takenAt.length > 0)
            drawDate = new Date(l.takenAt + "T00:00:00")
        page.applyAnalyte()
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
                title: page.lockAnalyte ? page.lockedLabel()
                     : (labId >= 0 ? qsTr("Edit result") : qsTr("New result"))
            }

            ComboBox {
                id: analyteCombo
                visible: !page.lockAnalyte
                label: qsTr("Analyte")
                menu: ContextMenu {
                    Repeater {
                        model: page.names
                        MenuItem { text: modelData }
                    }
                }
                onCurrentIndexChanged: page.applyAnalyte()
            }

            TextField {
                id: customField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: !page.lockAnalyte && page.isCustom()
                label: qsTr("Custom analyte")
                placeholderText: qsTr("Any test you had done")
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: page.save()
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                TextField {
                    id: valueField
                    width: parent.width * 0.5
                    label: qsTr("Value")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {}
                }

                ComboBox {
                    id: unitCombo
                    width: parent.width * 0.5 - Theme.paddingMedium
                    label: qsTr("Unit")
                    menu: ContextMenu {
                        Repeater {
                            model: page.units
                            MenuItem { text: modelData }
                        }
                    }
                }
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                visible: page.referenceText.length > 0

                Label {
                    width: parent.width
                    text: page.referenceText
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
            }

            ValueButton {
                label: qsTr("Draw date")
                value: Qt.formatDate(page.drawDate, "d MMM yyyy")
                onClicked: {
                    dateDialog.date = page.drawDate
                    dateDialog.open()
                }
            }

            TextField {
                id: labField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Lab")
                placeholderText: qsTr("Hospital, clinic or lab")
            }

            TextArea {
                id: notesField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Notes")
                placeholderText: qsTr("Anything you want to remember")
            }
        }
    }

    DatePickerDialog {
        id: dateDialog
        onAccepted: page.drawDate = selectedDate
    }
}
