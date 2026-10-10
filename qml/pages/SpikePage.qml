// TEMPORARY reminder probe — spike/reminders branch only. Delete after P4.
//
// Findings: a sandboxed app CANNOT see the real calendar (it lives in
// ~/.local/share/system/privileged/, group "privileg"), so direct writes via
// org.nemomobile.calendar land in an empty fallback DB. The supported path is
// the Calendar UI's D-Bus import: com.jolla.calendar.ui.importIcsData(ics),
// which Calendar.permission explicitly allows.
import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
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
    function append(m) { log += m + "\n"; console.log("[spike] " + m) }

    function buildIcs(minutesAhead) {
        var start = new Date(Date.now() + minutesAhead * 60000)
        return "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//dollfin//spike//EN\r\n"
            + "BEGIN:VEVENT\r\nUID:dollfin-probe@dollfin.local\r\n"
            + "DTSTAMP:" + icalUtc(new Date()) + "\r\n"
            + "DTSTART:" + icalLocal(start) + "\r\nDURATION:PT15M\r\n"
            + "RRULE:FREQ=DAILY;INTERVAL=2\r\n"
            + "SUMMARY:Dollfin probe dose\r\n"
            + "BEGIN:VALARM\r\nACTION:DISPLAY\r\nDESCRIPTION:Dollfin probe dose\r\nTRIGGER:-PT1M\r\nEND:VALARM\r\n"
            + "END:VEVENT\r\nEND:VCALENDAR\r\n"
    }

    DBusInterface {
        id: calendarUi
        service: "com.jolla.calendar.ui"
        path: "/com/jolla/calendar/ui"
        iface: "com.jolla.calendar.ui"
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
                text: "defaultNotebook: '" + Calendar.defaultNotebook + "'"
                    + "\n(blank is expected: the sandbox cannot see the privileged calendar DB)"
            }

            Button {
                text: "Open Calendar import (every 2 days)"
                onClicked: {
                    var ics = buildIcs(3)
                    append("calling com.jolla.calendar.ui.importIcsData (" + ics.length + " bytes)")
                    calendarUi.call("importIcsData", [ics],
                        function() { append("importIcsData: call returned") },
                        function(err) { append("importIcsData error: " + err) })
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
