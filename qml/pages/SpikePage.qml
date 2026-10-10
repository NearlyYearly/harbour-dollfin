// TEMPORARY reminder probe — spike/reminders branch only. Delete after P4.
// Tests whether a sandboxed app can write calendar events (and therefore get
// reliable timed alarms) via org.nemomobile.calendar.
import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

Page {
    id: page

    property string log: ""

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function icalUtc(d) {
        return d.getUTCFullYear() + pad(d.getUTCMonth() + 1) + pad(d.getUTCDate()) + "T"
             + pad(d.getUTCHours()) + pad(d.getUTCMinutes()) + pad(d.getUTCSeconds()) + "Z"
    }
    function icalLocal(d) {
        return d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + "T"
             + pad(d.getHours()) + pad(d.getMinutes()) + "00"
    }
    function append(msg) { log += msg + "\n"; console.log("[spike] " + msg) }

    NotebookQuery {
        id: notebookQuery
        targetUid: Calendar.defaultNotebook
    }

    ImportModel {
        id: importer
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col

            width: page.width
            spacing: Theme.paddingMedium

            PageHeader { title: "Reminder spike" }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                text: "defaultNotebook: " + Calendar.defaultNotebook
                    + "\nname: " + notebookQuery.name
                    + "\nlocalCalendar: " + notebookQuery.localCalendar
                    + "\nreadOnly: " + notebookQuery.isReadOnly
            }

            Button {
                text: "Import every-2-days event (+2 min)"
                onClicked: {
                    var start = new Date(Date.now() + 2 * 60000)
                    var ics = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//dollfin//spike//EN\r\n"
                        + "BEGIN:VEVENT\r\nUID:dollfin-probe@dollfin.local\r\n"
                        + "DTSTAMP:" + icalUtc(new Date()) + "\r\n"
                        + "DTSTART:" + icalLocal(start) + "\r\nDURATION:PT15M\r\n"
                        + "RRULE:FREQ=DAILY;INTERVAL=2\r\n"
                        + "SUMMARY:Dollfin probe dose\r\n"
                        + "BEGIN:VALARM\r\nACTION:DISPLAY\r\nDESCRIPTION:Dollfin probe dose\r\nTRIGGER:-PT1M\r\nEND:VALARM\r\n"
                        + "END:VEVENT\r\nEND:VCALENDAR\r\n"
                    importer.icsString = ics
                    importer.targetNotebook = Calendar.defaultNotebook
                    append("import error=" + importer.error + ", saving...")
                    var ok = importer.save()
                    append("import save() -> " + ok + ", error=" + importer.error)
                }
            }

            Button {
                text: "Create daily event via API (+3 min)"
                onClicked: {
                    try {
                        var ev = Calendar.createNewEvent()
                        ev.displayLabel = "Dollfin API probe"
                        ev.description = "spike"
                        ev.calendarUid = Calendar.defaultNotebook
                        ev.setStartTime(new Date(Date.now() + 3 * 60000), Qt.LocalTime)
                        ev.recur = CalendarEvent.RecurDaily
                        ev.reminder = 1
                        ev.save()
                        append("createNewEvent().save() called")
                    } catch (e) {
                        append("createNewEvent threw: " + e)
                    }
                }
            }

            Button {
                text: "Remove probe events"
                onClicked: {
                    Calendar.removeAll("dollfin-probe@dollfin.local")
                    append("removeAll(dollfin-probe@dollfin.local) called")
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: log
            }
        }
    }
}
