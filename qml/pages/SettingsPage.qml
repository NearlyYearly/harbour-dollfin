// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property string lastResult: ""

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Settings") }

            SectionHeader { text: qsTr("Reminders") }

            TextSwitch {
                id: remindersSwitch
                text: qsTr("Calendar reminders")
                description: qsTr("Add each dose to a calendar so your phone reminds you on time. Recommended.")
                checked: app.remindersEnabled
                onCheckedChanged: {
                    if (checked && !app.remindersConsent) {
                        consentDialog.open()
                    } else {
                        app.setRemindersEnabled(checked)
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                visible: !app.remindersConsent
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("Dollfin never sends anything to a server. Reminders only leave the " +
                           "phone if you put them in a calendar that syncs to the cloud.")
            }

            Button {
                x: Theme.horizontalPageMargin
                visible: app.remindersEnabled
                text: qsTr("Update calendar reminders")
                onClicked: {
                    if (app.syncCalendarReminders())
                        page.lastResult = qsTr("Sent to the calendar app for confirmation.")
                    else
                        page.lastResult = qsTr("Nothing to sync yet, or the calendar app is unavailable.")
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                visible: app.remindersEnabled
                text: qsTr("Export .ics file")
                onClicked: {
                    var path = app.exportIcs()
                    page.lastResult = path.length > 0
                        ? qsTr("Saved to %1").arg(path)
                        : qsTr("Nothing to export yet.")
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                visible: text.length > 0
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: page.lastResult
            }

            SectionHeader { text: qsTr("About") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Dollfin keeps your medication data on this device. It has no network " +
                           "access and never collects anything.")
            }
        }
    }

    Dialog {
        id: consentDialog

        onAccepted: {
            app.setRemindersConsent(true)
            app.setRemindersEnabled(true)
        }
        onRejected: remindersSwitch.checked = false

        Column {
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader { title: qsTr("Calendar reminders") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Dollfin will add each dose as an event in a calendar you choose. " +
                           "If that calendar is synced to a cloud service (Google, iCloud, " +
                           "CalDAV), your medication names will be uploaded there too. " +
                           "For privacy, pick a calendar that stays on this phone.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("You can turn calendar reminders off here at any time.")
            }
        }
    }
}
