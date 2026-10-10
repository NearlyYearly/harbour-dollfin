// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property string lastResult: ""
    property string exportedPath: ""

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
                    if (checked && !app.remindersConsent)
                        consentDialog.open()
                    else
                        app.setRemindersEnabled(checked)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                visible: !app.remindersConsent
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("Dollfin never sends anything to a server. Reminders only leave the phone if you put them in a calendar that syncs to the cloud.")
            }

            Button {
                x: Theme.horizontalPageMargin
                visible: app.remindersEnabled
                text: qsTr("Update calendar reminders")
                onClicked: {
                    if (app.syncCalendarReminders())
                        page.lastResult = qsTr("Sent to the Calendar app for confirmation.")
                    else
                        page.lastResult = qsTr("Could not reach the Calendar app. Make sure a calendar is set up.")
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                visible: app.remindersEnabled
                text: qsTr("Export .ics file")
                onClicked: {
                    page.exportedPath = app.exportIcs()
                    if (page.exportedPath.length > 0) {
                        page.lastResult = qsTr("Saved to %1").arg(page.exportedPath)
                        openDialog.open()
                    } else {
                        page.lastResult = qsTr("Nothing to export yet. Add a schedule first.")
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                visible: text.length > 0
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                text: page.lastResult
            }

            SectionHeader { text: qsTr("Backup") }

            Button {
                x: Theme.horizontalPageMargin
                text: qsTr("Export backup")
                onClicked: {
                    var path = app.exportBackup()
                    page.lastResult = path.length > 0
                        ? qsTr("Backup saved to %1").arg(path)
                        : qsTr("Could not write the backup.")
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                text: qsTr("Import backup")
                onClicked: importDialog.open()
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("Backups are written to %1 as JSON. To restore, put a backup file there and import.").arg(app.backupPath())
            }

            SectionHeader { text: qsTr("About") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Dollfin keeps your medication data on this device. It has no network access and never collects anything.")
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

            DialogHeader {
                dialog: consentDialog
                title: qsTr("Calendar reminders")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Dollfin will add each dose as an event in a calendar you choose. If that calendar is synced to a cloud service (Google, iCloud, CalDAV), your medication names will be uploaded there too. For privacy, pick a calendar that stays on this phone.")
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

    Dialog {
        id: openDialog

        onAccepted: app.openInCalendar(page.exportedPath)

        Column {
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                dialog: openDialog
                title: qsTr("Open in Calendar?")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("The .ics file is saved. Import it into a calendar now?")
            }
        }
    }

    Dialog {
        id: importDialog

        onAccepted: {
            page.lastResult = app.importBackup("")
                ? qsTr("Backup imported.")
                : qsTr("Import failed. Is there a backup file?")
        }

        Column {
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                dialog: importDialog
                title: qsTr("Import backup?")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("This replaces everything currently in Dollfin with the contents of the backup file.")
            }
        }
    }
}
