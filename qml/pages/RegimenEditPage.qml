// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property int medicationId: -1
    property int regimenId: -1

    property var times: []
    property var weekdays: []
    property var startDate: new Date()
    property bool hasEndDate: false
    property var endDate: new Date()
    property int repeatMode: 0 // 0 daily, 1 every N days, 2 weekly

    allowedOrientations: Orientation.All

    function pad(n) { return (n < 10 ? "0" : "") + n }

    function save() {
        if (times.length === 0) {
            timeHint.visible = true
            return
        }
        var data = {
            "id": regimenId,
            "medicationId": medicationId,
            "dose": parseFloat(doseField.text) || 0,
            "unit": unitField.text,
            "route": routeField.text,
            "intervalDays": repeatMode === 1 ? Math.max(1, parseInt(intervalField.text) || 1) : 1,
            "daysOfWeek": repeatMode === 2 ? weekdays : [],
            "times": times,
            "startDate": Qt.formatDate(startDate, "yyyy-MM-dd"),
            "endDate": hasEndDate ? Qt.formatDate(endDate, "yyyy-MM-dd") : "",
            "active": true
        }
        if (app.saveRegimen(data))
            pageStack.pop()
    }

    function toggleWeekday(day) {
        var d = weekdays.slice()
        var i = d.indexOf(day)
        if (i >= 0)
            d.splice(i, 1)
        else
            d.push(day)
        d.sort()
        weekdays = d
    }

    Component.onCompleted: {
        if (regimenId >= 0) {
            var r = app.regimen(regimenId)
            doseField.text = r.dose > 0 ? String(r.dose) : ""
            unitField.text = r.unit
            routeField.text = r.route
            times = r.times
            weekdays = r.daysOfWeek
            if (r.daysOfWeek.length > 0) {
                repeatMode = 2
            } else if (r.intervalDays > 1) {
                repeatMode = 1
                intervalField.text = String(r.intervalDays)
            } else {
                repeatMode = 0
            }
            startDate = new Date(r.startDate)
            if (r.endDate) {
                hasEndDate = true
                endDate = new Date(r.endDate)
            }
        }
        repeatCombo.currentIndex = repeatMode
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
                title: regimenId >= 0 ? qsTr("Edit schedule") : qsTr("New schedule")
            }

            TextField {
                id: doseField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Dose")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator {}
            }

            TextField {
                id: unitField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Unit")
                placeholderText: qsTr("mg")
            }

            TextField {
                id: routeField
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Route")
                placeholderText: qsTr("oral, gel, patch, injection…")
            }

            ComboBox {
                id: repeatCombo
                label: qsTr("Repeats")
                menu: ContextMenu {
                    MenuItem { text: qsTr("Every day") }
                    MenuItem { text: qsTr("Every N days") }
                    MenuItem { text: qsTr("Weekly") }
                }
                onCurrentIndexChanged: page.repeatMode = currentIndex
            }

            TextField {
                id: intervalField
                visible: page.repeatMode === 1
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                label: qsTr("Number of days")
                inputMethodHints: Qt.ImhDigitsOnly
                text: "2"
            }

            Flow {
                visible: page.repeatMode === 2
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Repeater {
                    model: [qsTr("Mon"), qsTr("Tue"), qsTr("Wed"), qsTr("Thu"),
                            qsTr("Fri"), qsTr("Sat"), qsTr("Sun")]
                    Button {
                        text: modelData
                        width: (parent.width - 3 * Theme.paddingSmall) / 4
                        highlighted: page.weekdays.indexOf(index + 1) >= 0
                        onClicked: page.toggleWeekday(index + 1)
                    }
                }
            }

            SectionHeader { text: qsTr("Times") }

            Repeater {
                model: page.times
                ListItem {
                    contentHeight: Theme.itemSizeSmall
                    width: column.width
                    Label {
                        x: Theme.horizontalPageMargin
                        text: modelData
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IconButton {
                        anchors.right: parent.right
                        icon.source: "image://theme/icon-m-remove"
                        onClicked: {
                            var t = page.times.slice()
                            t.splice(index, 1)
                            page.times = t
                        }
                    }
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                text: qsTr("Add time")
                onClicked: {
                    timeDialog.hour = 8
                    timeDialog.minute = 0
                    timeDialog.open()
                }
            }

            Label {
                id: timeHint
                visible: false
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Add at least one time")
                color: Theme.errorColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            SectionHeader { text: qsTr("Dates") }

            ValueButton {
                label: qsTr("Starts")
                value: Qt.formatDate(page.startDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    startDialog.date = page.startDate
                    startDialog.open()
                }
            }

            TextSwitch {
                text: qsTr("Has an end date")
                checked: page.hasEndDate
                onCheckedChanged: page.hasEndDate = checked
            }

            ValueButton {
                visible: page.hasEndDate
                label: qsTr("Ends")
                value: Qt.formatDate(page.endDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    endDialog.date = page.endDate
                    endDialog.open()
                }
            }
        }
    }

    TimePickerDialog {
        id: timeDialog
        onAccepted: {
            var t = page.times.slice()
            t.push(page.pad(hour) + ":" + page.pad(minute))
            t.sort()
            page.times = t
            timeHint.visible = false
        }
    }

    DatePickerDialog {
        id: startDialog
        onAccepted: page.startDate = selectedDate
    }

    DatePickerDialog {
        id: endDialog
        onAccepted: page.endDate = selectedDate
    }
}
