/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    readonly property bool hasActiveMode: Plasmoid.activeModeId.length > 0
    readonly property bool hasActiveTimer: Plasmoid.remainingSeconds > 0

    toolTipMainText: root.hasActiveMode
        ? ("Concentración: " + Plasmoid.activeModeName)
        : (Plasmoid.dndActive ? "No Molestar activo" : "Modos de Concentración")
    toolTipSubText: root.hasActiveTimer
        ? ("Tiempo restante: " + Plasmoid.remainingFormatted)
        : (root.hasActiveMode ? "Notificaciones silenciadas" : "Pulsa para elegir un modo (Trabajo, Personal, Lectura, Descanso)")

    compactRepresentation: Item {
        id: compactRoot

        Layout.minimumWidth: compactPillRow.implicitWidth + Kirigami.Units.largeSpacing * 2.2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.fillHeight: true

        Behavior on Layout.minimumWidth {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        LiquidGlassCard {
            id: compactPill
            anchors.centerIn: parent
            width: Math.max(28, parent.width - 4)
            height: Math.max(20, Math.min(parent.height - 2, Kirigami.Units.gridUnit * 1.75))
            radius: height / 2
            glassStyle: "shell"
            isHighlighted: root.hasActiveMode || Plasmoid.dndActive

            RowLayout {
                id: compactPillRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 1.2

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    Layout.alignment: Qt.AlignVCenter
                    source: root.hasActiveMode
                        ? Plasmoid.activeModeIcon
                        : (Plasmoid.dndActive ? "notifications-disabled" : "weather-clear-night")
                    color: (root.hasActiveMode || Plasmoid.dndActive) ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                }

                PlasmaComponents3.Label {
                    visible: root.hasActiveMode || Plasmoid.dndActive
                    Layout.alignment: Qt.AlignVCenter
                    text: root.hasActiveMode ? Plasmoid.activeModeName : "No Molestar"
                    font.pixelSize: Kirigami.Units.gridUnit * 0.68
                    font.bold: true
                    color: Kirigami.Theme.textColor
                }

                PlasmaComponents3.Label {
                    visible: root.hasActiveTimer
                    Layout.alignment: Qt.AlignVCenter
                    text: "· " + Plasmoid.remainingFormatted
                    font.pixelSize: Kirigami.Units.gridUnit * 0.64
                    font.family: "monospace"
                    color: Kirigami.Theme.highlightColor
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        if (root.hasActiveMode) {
                            Plasmoid.deactivateMode();
                        } else {
                            Plasmoid.toggleDnd();
                        }
                    } else {
                        root.expanded = !root.expanded;
                    }
                }
            }
        }
    }

    fullRepresentation: Item {
        id: fullRoot

        implicitWidth: Kirigami.Units.gridUnit * 21
        implicitHeight: Kirigami.Units.gridUnit * 23
        Layout.minimumWidth: Kirigami.Units.gridUnit * 21
        Layout.minimumHeight: Kirigami.Units.gridUnit * 23
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.preferredHeight: Kirigami.Units.gridUnit * 23

        LiquidGlassCard {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            glassStyle: "shell"
            glassOpacity: 0.90
            isHighlighted: root.hasActiveMode

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.mediumSpacing

                // 1. Header Card: Active Focus Status + Countdown + Quick Duration Pills
                LiquidGlassCard {
                    Layout.fillWidth: true
                    implicitHeight: headerCol.implicitHeight + Kirigami.Units.largeSpacing * 1.6
                    Layout.preferredHeight: implicitHeight
                    glassStyle: "card"
                    isHighlighted: root.hasActiveMode

                    ColumnLayout {
                        id: headerCol
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.mediumSpacing * 1.2
                        spacing: Kirigami.Units.smallSpacing * 1.3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.mediumSpacing

                            Rectangle {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                                radius: width / 2
                                color: root.hasActiveMode
                                    ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22)
                                    : Kirigami.Theme.alternateBackgroundColor
                                border.width: 1
                                border.color: root.hasActiveMode ? Kirigami.Theme.highlightColor : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.18)

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Kirigami.Units.iconSizes.smallMedium
                                    height: Kirigami.Units.iconSizes.smallMedium
                                    source: root.hasActiveMode
                                        ? Plasmoid.activeModeIcon
                                        : (Plasmoid.dndActive ? "notifications-disabled" : "weather-clear-night")
                                    color: root.hasActiveMode ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: root.hasActiveMode
                                        ? ("Concentración: " + Plasmoid.activeModeName)
                                        : "Concentración inactiva"
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.82
                                    font.bold: true
                                    color: Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: root.hasActiveTimer
                                        ? ("Temporizador activo · " + Plasmoid.remainingFormatted)
                                        : (root.hasActiveMode
                                            ? "Sin límite de tiempo (∞)"
                                            : "Selecciona un perfil o inicia un Pomodoro")
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.66
                                    color: root.hasActiveTimer ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                    elide: Text.ElideRight
                                }
                            }

                            // Large live timer badge when active
                            LiquidGlassCard {
                                visible: root.hasActiveTimer
                                glassStyle: "recessed"
                                implicitWidth: timerBadgeRow.implicitWidth + Kirigami.Units.mediumSpacing * 1.6
                                implicitHeight: Kirigami.Units.gridUnit * 1.55
                                Layout.preferredWidth: implicitWidth
                                Layout.preferredHeight: implicitHeight

                                RowLayout {
                                    id: timerBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Kirigami.Icon {
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14
                                        source: "chronometer"
                                        color: Kirigami.Theme.highlightColor
                                    }

                                    QQC2.Label {
                                        text: Plasmoid.remainingFormatted
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.72
                                        font.bold: true
                                        font.family: "monospace"
                                        color: Kirigami.Theme.highlightColor
                                    }
                                }
                            }
                        }

                        // Quick duration pills: 15m, 25m, 45m, 60m, ∞
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Repeater {
                                model: [
                                    { label: "15m", minutes: 15 },
                                    { label: "25m", minutes: 25 },
                                    { label: "45m", minutes: 45 },
                                    { label: "60m", minutes: 60 },
                                    { label: "∞", minutes: 0 }
                                ]

                                delegate: LiquidGlassCard {
                                    id: pillCard
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Kirigami.Units.gridUnit * 1.45
                                    Layout.preferredHeight: implicitHeight
                                    glassStyle: "recessed"
                                    readonly property bool isSelectedDuration: {
                                        if (!root.hasActiveMode) {
                                            return false;
                                        }
                                        if (pillCard.modelData.minutes === 0) {
                                            return Plasmoid.remainingSeconds === 0;
                                        }
                                        return Math.abs(Plasmoid.remainingSeconds - pillCard.modelData.minutes * 60) <= 59;
                                    }
                                    isHighlighted: isSelectedDuration

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: pillCard.modelData.label
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.66
                                        font.bold: pillCard.isSelectedDuration
                                        color: pillCard.isSelectedDuration ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Plasmoid.startCustomTimer(pillCard.modelData.minutes);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. 2x2 Grid of Liquid Glass Focus Mode Cards (Trabajo, Personal, Lectura, Descanso)
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: Kirigami.Units.mediumSpacing
                    columnSpacing: Kirigami.Units.mediumSpacing

                    Repeater {
                        model: Plasmoid.modes

                        delegate: LiquidGlassCard {
                            id: modeCard
                            required property var modelData

                            readonly property string modeId: modeCard.modelData.id ?? ""
                            readonly property string modeName: modeCard.modelData.name ?? ""
                            readonly property string modeIcon: modeCard.modelData.icon ?? "weather-clear-night"
                            readonly property string modeSubtitle: modeCard.modelData.subtitle ?? ""
                            readonly property int defaultMins: modeCard.modelData.defaultTimerMinutes ?? 0
                            readonly property string schemeName: modeCard.modelData.colorScheme ?? ""
                            readonly property bool isCurrent: Plasmoid.activeModeId === modeId

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: Kirigami.Units.gridUnit * 5.2
                            glassStyle: "card"
                            isHighlighted: isCurrent

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.mediumSpacing * 1.1
                                spacing: Kirigami.Units.smallSpacing

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing

                                    Rectangle {
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.85
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.85
                                        radius: width / 2
                                        color: modeCard.isCurrent
                                            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22)
                                            : Kirigami.Theme.alternateBackgroundColor
                                        border.width: 1
                                        border.color: modeCard.isCurrent ? Kirigami.Theme.highlightColor : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.16)

                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            width: Kirigami.Units.iconSizes.small
                                            height: Kirigami.Units.iconSizes.small
                                            source: modeCard.modeIcon
                                            color: modeCard.isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Default timer or color scheme badge
                                    Rectangle {
                                        visible: modeCard.defaultMins > 0 || modeCard.schemeName.length > 0
                                        implicitWidth: badgeText.implicitWidth + Kirigami.Units.smallSpacing * 1.8
                                        implicitHeight: Kirigami.Units.gridUnit * 1.05
                                        Layout.preferredWidth: implicitWidth
                                        Layout.preferredHeight: implicitHeight
                                        radius: height / 2
                                        color: modeCard.isCurrent
                                            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                                            : Kirigami.Theme.alternateBackgroundColor
                                        border.width: 1
                                        border.color: modeCard.isCurrent
                                            ? Kirigami.Theme.highlightColor
                                            : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.14)

                                        QQC2.Label {
                                            id: badgeText
                                            anchors.centerIn: parent
                                            text: modeCard.defaultMins > 0
                                                ? (modeCard.defaultMins + " min")
                                                : "Oscuro"
                                            font.pixelSize: Kirigami.Units.gridUnit * 0.56
                                            font.bold: true
                                            color: modeCard.isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                        }
                                    }
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: modeCard.modeName
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.78
                                    font.bold: true
                                    color: modeCard.isCurrent ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: modeCard.modeSubtitle
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.60
                                    color: modeCard.isCurrent ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Plasmoid.toggleMode(modeCard.modeId);
                                }
                            }
                        }
                    }
                }

                // 3. Footer Controls: Quick Toggle for "No Molestar (DND)" & "Desactivar Concentración"
                LiquidGlassCard {
                    Layout.fillWidth: true
                    implicitHeight: footerCol.implicitHeight + Kirigami.Units.mediumSpacing * 1.6
                    Layout.preferredHeight: implicitHeight
                    glassStyle: "card"
                    isHighlighted: Plasmoid.dndActive && !root.hasActiveMode

                    ColumnLayout {
                        id: footerCol
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.mediumSpacing
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.mediumSpacing

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                source: Plasmoid.dndActive
                                    ? "notifications-disabled"
                                    : "preferences-desktop-notification-bell"
                                color: Plasmoid.dndActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: "No Molestar (DND)"
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.72
                                    font.bold: true
                                    color: Kirigami.Theme.textColor
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: Plasmoid.dndActive
                                        ? "Notificaciones emergentes silenciadas"
                                        : "Notificaciones del sistema permitidas"
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.58
                                    color: Kirigami.Theme.disabledTextColor
                                    elide: Text.ElideRight
                                }
                            }

                            QQC2.Switch {
                                checked: Plasmoid.dndActive
                                onToggled: {
                                    Plasmoid.setDndActive(checked);
                                }
                            }
                        }

                        // "Desactivar Concentración" button when a mode is active
                        LiquidGlassCard {
                            visible: root.hasActiveMode
                            Layout.fillWidth: true
                            implicitHeight: Kirigami.Units.gridUnit * 1.85
                            Layout.preferredHeight: implicitHeight
                            glassStyle: "recessed"
                            isHighlighted: true

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                    source: "dialog-cancel"
                                    color: Kirigami.Theme.highlightColor
                                }

                                QQC2.Label {
                                    text: "Desactivar Concentración"
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.68
                                    font.bold: true
                                    color: Kirigami.Theme.highlightColor
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Plasmoid.deactivateMode();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
