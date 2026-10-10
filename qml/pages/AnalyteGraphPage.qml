// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

import QtQuick 2.0
import Sailfish.Silica 1.0

// One analyte, one unit at a time (D-026/D-028/D-030). No chart dependency: a
// Canvas plots the line and points. A numeric band is drawn only for
// unambiguous ranges (D-029). With many results the plot scrolls horizontally
// and each point can be tapped.
Page {
    id: page

    property var summary
    property string unit: summary ? summary.unit : ""
    property int selectedIndex: -1

    property real gutterWidth: Theme.fontSizeSmall * 3.4
    property real padTop: Theme.paddingLarge
    property real padBottom: Theme.fontSizeLarge * 1.4
    property real padInnerLeft: Theme.paddingLarge
    property real padInnerRight: Theme.paddingLarge
    property real minPointSpacing: Theme.itemSizeSmall
    property real strokeWidth: Math.max(3, Theme.paddingSmall / 2)
    property real pointRadius: Math.max(3, Theme.paddingSmall / 2)

    allowedOrientations: Orientation.All

    property var allPoints: {
        var all = app.labs
        var out = []
        var key = summary ? summary.key : ""
        for (var i = 0; i < all.length; ++i) {
            if (all[i].analyteKey === key)
                out.push(all[i])
        }
        return out
    }

    property var unitsUsed: {
        var seen = {}
        var out = []
        for (var i = 0; i < allPoints.length; ++i) {
            var u = allPoints[i].unit
            if (!seen[u]) {
                seen[u] = true
                out.push(u)
            }
        }
        return out
    }

    // Points for the selected unit, oldest first.
    property var points: {
        var out = []
        for (var i = 0; i < allPoints.length; ++i) {
            if (allPoints[i].unit === unit) {
                var d = new Date(allPoints[i].takenAt + "T00:00:00")
                out.push({ t: d.getTime(), v: allPoints[i].value,
                           lab: allPoints[i].lab })
            }
        }
        out.sort(function(a, b) { return a.t - b.t })
        return out
    }

    // The plot is at least as wide as the viewport, and grows with the number
    // of points so they never bunch up.
    property real contentWidth: Math.max(flick.width, minimumContentWidth())
    function minimumContentWidth() {
        var n = page.points.length
        if (n <= 1)
            return 0
        return (n - 1) * page.minPointSpacing + page.padInnerLeft + page.padInnerRight
    }

    function pointX(i) {
        var n = page.points.length
        var plotW = Math.max(1, page.contentWidth - page.padInnerLeft - page.padInnerRight)
        if (n <= 1)
            return page.padInnerLeft + plotW / 2
        return page.padInnerLeft + i * plotW / (n - 1)
    }

    property bool bandShown: summary && summary.hasBand && unit === summary.referenceUnit
    property real valueMin: {
        if (points.length === 0)
            return 0
        var m = points[0].v
        for (var i = 1; i < points.length; ++i)
            m = Math.min(m, points[i].v)
        if (bandShown)
            m = Math.min(m, summary.bandLow)
        return m
    }
    property real valueMax: {
        if (points.length === 0)
            return 0
        var m = points[0].v
        for (var i = 1; i < points.length; ++i)
            m = Math.max(m, points[i].v)
        if (bandShown)
            m = Math.max(m, summary.bandHigh)
        return m
    }
    // Snap the axis to clean 1/2/5 steps that still enclose the data and, when
    // shown, the whole reference band (so a full range stays visible even if
    // every result sits inside it).
    function niceStep(range) {
        if (!(range > 0))
            return 1
        var raw = range / 4
        var magnitude = Math.pow(10, Math.floor(Math.log(raw) / Math.LN10))
        var normalized = raw / magnitude
        if (normalized <= 1)
            return magnitude
        if (normalized <= 2)
            return 2 * magnitude
        if (normalized <= 5)
            return 5 * magnitude
        return 10 * magnitude
    }

    property real axisStep: {
        var range = valueMax - valueMin
        if (range === 0)
            range = Math.max(Math.abs(valueMax) * 0.2, 1)
        return niceStep(range)
    }
    property real axisMin: valueMin === valueMax
                           ? valueMin - axisStep
                           : Math.floor(valueMin / axisStep) * axisStep
    property real axisMax: valueMin === valueMax
                           ? valueMin + axisStep
                           : Math.ceil(valueMax / axisStep) * axisStep
    property int axisDecimals: Math.max(0, Math.min(4,
        -Math.floor(Math.log(axisStep) / Math.LN10)))

    function fmtAxis(v) {
        return parseFloat(v.toFixed(axisDecimals)) + " " + unit
    }

    function dateText(index) {
        if (index < 0 || index >= page.points.length)
            return ""
        return Qt.formatDate(new Date(page.points[index].t), "d MMM yyyy")
    }

    function selectedText() {
        if (page.selectedIndex < 0 || page.selectedIndex >= page.points.length)
            return ""
        var p = page.points[page.selectedIndex]
        var text = p.v + " " + page.unit + " · " + page.dateText(page.selectedIndex)
        if (p.lab && p.lab.length > 0)
            text += " · " + p.lab
        return text
    }

    // Nearest point by horizontal distance, so a vertical tap anywhere still
    // selects that result. Tapping the same point again clears it.
    function selectAt(x) {
        var n = page.points.length
        if (n === 0)
            return
        var best = -1
        var bestDistance = 1e9
        for (var i = 0; i < n; ++i) {
            var distance = Math.abs(page.pointX(i) - x)
            if (distance < bestDistance) {
                bestDistance = distance
                best = i
            }
        }
        var threshold = Math.max(page.minPointSpacing / 2, Theme.paddingLarge)
        page.selectedIndex = (bestDistance <= threshold && best !== page.selectedIndex)
                            ? best : -1
    }

    function draw(ctx, w, h) {
        var n = page.points.length
        if (n === 0 || w <= 0 || h <= 0)
            return

        // The canvas is not cleared for us, so wipe it before redrawing.
        ctx.clearRect(0, 0, w, h)

        var plotY = page.padTop
        var plotW = Math.max(1, w - page.padInnerLeft - page.padInnerRight)
        var plotH = Math.max(1, h - page.padTop - page.padBottom)

        function yFor(v) {
            return plotY + (page.axisMax - v) / (page.axisMax - page.axisMin) * plotH
        }

        if (page.bandShown) {
            var yTop = yFor(page.summary.bandHigh)
            var yBot = yFor(page.summary.bandLow)
            ctx.fillStyle = Qt.rgba(Theme.highlightColor.r, Theme.highlightColor.g,
                                    Theme.highlightColor.b, 0.15)
            ctx.fillRect(page.padInnerLeft, yTop, plotW, yBot - yTop)
        }

        ctx.strokeStyle = Theme.secondaryColor
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(page.padInnerLeft, plotY)
        ctx.lineTo(page.padInnerLeft, plotY + plotH)
        ctx.lineTo(page.padInnerLeft + plotW, plotY + plotH)
        ctx.stroke()

        if (n > 1) {
            ctx.strokeStyle = Theme.highlightColor
            ctx.lineWidth = page.strokeWidth
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.beginPath()
            for (var i = 0; i < n; ++i) {
                var x = page.pointX(i)
                var y = yFor(page.points[i].v)
                if (i === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }
            ctx.stroke()
        }

        // Guide line for the selected point.
        if (page.selectedIndex >= 0 && page.selectedIndex < n) {
            var sx = page.pointX(page.selectedIndex)
            ctx.strokeStyle = Theme.secondaryHighlightColor
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(sx, plotY)
            ctx.lineTo(sx, plotY + plotH)
            ctx.stroke()
        }

        for (var j = 0; j < n; ++j) {
            var px = page.pointX(j)
            var py = yFor(page.points[j].v)
            ctx.beginPath()
            ctx.arc(px, py, page.pointRadius, 0, 2 * Math.PI)
            ctx.fillStyle = Theme.highlightColor
            ctx.fill()
            if (j === page.selectedIndex) {
                ctx.lineWidth = page.strokeWidth / 2
                ctx.strokeStyle = Theme.primaryColor
                ctx.stroke()
            }
        }
    }

    Component.onCompleted: {
        if (page.unitsUsed.length > 1) {
            var index = page.unitsUsed.indexOf(page.summary.unit)
            unitCombo.currentIndex = index >= 0 ? index : 0
        }
        chart.requestPaint()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

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
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            ComboBox {
                id: unitCombo
                visible: page.unitsUsed.length > 1
                label: qsTr("Unit")
                menu: ContextMenu {
                    Repeater {
                        model: page.unitsUsed
                        MenuItem { text: modelData }
                    }
                }
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < page.unitsUsed.length)
                        page.unit = page.unitsUsed[currentIndex]
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: page.unitsUsed.length > 1
                text: qsTr("Results are shown per unit; they are not converted.")
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Item {
                id: chartArea
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Math.max(Theme.itemSizeLarge * 3, page.height * 0.45)

                Label {
                    id: maxLabel
                    anchors { left: parent.left; top: parent.top; topMargin: page.padTop }
                    width: page.gutterWidth
                    horizontalAlignment: Text.AlignRight
                    text: page.points.length > 0 ? page.fmtAxis(page.axisMax) : ""
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    elide: Text.ElideRight
                }

                Label {
                    id: minLabel
                    anchors { left: parent.left; bottom: parent.bottom; bottomMargin: page.padBottom }
                    width: page.gutterWidth
                    horizontalAlignment: Text.AlignRight
                    text: page.points.length > 0 ? page.fmtAxis(page.axisMin) : ""
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    elide: Text.ElideRight
                }

                Flickable {
                    id: flick
                    anchors.left: parent.left
                    anchors.leftMargin: page.gutterWidth
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    contentWidth: page.contentWidth
                    contentHeight: height
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    visible: page.points.length > 0

                    Canvas {
                        id: chart
                        width: page.contentWidth
                        height: flick.height
                        onPaint: page.draw(getContext("2d"), width, height)

                        Connections {
                            target: page
                            onPointsChanged: chart.requestPaint()
                            onUnitChanged: chart.requestPaint()
                            onBandShownChanged: chart.requestPaint()
                            onSelectedIndexChanged: chart.requestPaint()
                        }
                    }

                    Repeater {
                        model: page.points
                        Label {
                            x: page.pointX(index) - page.minPointSpacing / 2
                            y: flick.height - page.padBottom + Theme.paddingSmall
                            width: page.minPointSpacing
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.formatDate(new Date(modelData.t), "d MMM")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.selectAt(mouse.x)
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: page.selectedIndex >= 0
                      ? page.selectedText()
                      : qsTr("Tap a point to see that result.")
                wrapMode: Text.WordWrap
                color: page.selectedIndex >= 0 ? Theme.highlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Illustrative only, not medical advice.")
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
    }
}
