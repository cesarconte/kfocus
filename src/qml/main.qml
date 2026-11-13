/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import CachyOS.UI
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    readonly property bool hasActiveMode: Plasmoid.activeModeId.length > 0
    readonly property bool hasActiveTimer: Plasmoid.remainingSeconds > 0

    // Paleta del plasmoide (regla Golden Gate): el color lo aporta
    // CachyPalette (paleta efectiva de la superficie real). La geometría
    // y el acento salen de CachyTheme, idénticos a los de una aplicación.
    readonly property color foreground: CachyPalette.text
    readonly property color dim: CachyPalette.textSecondary
    readonly property color accent: CachyPalette.accentText

    toolTipMainText: root.hasActiveMode
        ? ("Concentración: " + Plasmoid.activeModeName)
        : (Plasmoid.dndActive ? "No Molestar activo" : "Modos de Concentración")
    toolTipSubText: root.hasActiveTimer
        ? ("Tiempo restante: " + Plasmoid.remainingFormatted)
        : (root.hasActiveMode ? "Notificaciones silenciadas" : "Pulsa para elegir un modo (Trabajo, Personal, Lectura, Descanso)")

    compactRepresentation: Item {
        id: compactRoot

        readonly property bool showText: root.hasActiveMode || Plasmoid.dndActive

        Layout.minimumWidth: showText
            ? (compactContentRow.implicitWidth + CachyTheme.spacingSmall * 2)
            : (compactRoot.height > 0 ? compactRoot.height : Kirigami.Units.gridUnit * 1.8)
        Layout.preferredWidth: Layout.minimumWidth
        Layout.fillHeight: true

        Behavior on Layout.minimumWidth {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
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

        RowLayout {
            id: compactContentRow
            anchors.centerIn: parent
            spacing: CachyTheme.spacingSmall * 1.2

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.alignment: Qt.AlignVCenter
                source: (root.hasActiveMode && Plasmoid.activeModeIcon.length > 0)
                    ? (Plasmoid.activeModeIcon.endsWith("-symbolic") ? Plasmoid.activeModeIcon : (Plasmoid.activeModeIcon + "-symbolic"))
                    : "focus-symbolic"
                fallback: Qt.resolvedUrl("focus-symbolic.svg")
                isMask: true
            }

            PlasmaComponents3.Label {
                visible: compactRoot.showText
                Layout.alignment: Qt.AlignVCenter
                text: root.hasActiveMode ? Plasmoid.activeModeName : "No Molestar"
                font.pixelSize: Kirigami.Units.gridUnit * 0.68
                font.bold: true
                color: root.foreground
            }

            PlasmaComponents3.Label {
                visible: root.hasActiveTimer
                Layout.alignment: Qt.AlignVCenter
                text: "· " + Plasmoid.remainingFormatted
                font.pixelSize: Kirigami.Units.gridUnit * 0.64
                font.family: "monospace"
                color: root.accent
            }
        }
    }

    fullRepresentation: Item {
        id: fullRoot

        implicitWidth: Kirigami.Units.gridUnit * 21
        implicitHeight: Kirigami.Units.gridUnit * 36
        Layout.minimumWidth: Kirigami.Units.gridUnit * 21
        Layout.minimumHeight: Kirigami.Units.gridUnit * 36
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.preferredHeight: Kirigami.Units.gridUnit * 36

        Item {
            anchors.fill: parent
            anchors.margins: CachyTheme.spacingSmall

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: CachyTheme.spacingLarge
                spacing: CachyTheme.spacingMedium

                // 1. Header Card: Active Focus Status + Countdown + Quick Duration Pills
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: headerCol.implicitHeight + CachyTheme.spacingLarge * 1.6
                    Layout.preferredHeight: implicitHeight
                    radius: CachyTheme.spacingSmall
                    color: root.hasActiveMode
                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                        : CachyPalette.cardBackground
                    border.width: 1
                    border.color: root.hasActiveMode
                        ? root.accent
                        : CachyPalette.specularBorder

                    ColumnLayout {
                        id: headerCol
                        anchors.fill: parent
                        anchors.margins: CachyTheme.spacingMedium * 1.2
                        spacing: CachyTheme.spacingSmall * 1.3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: CachyTheme.spacingMedium

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                source: root.hasActiveMode
                                    ? Plasmoid.activeModeIcon
                                    : (Plasmoid.dndActive ? "notifications-disabled" : "preferences-system-time")
                                color: root.hasActiveMode ? root.accent : root.foreground
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: root.hasActiveMode
                                        ? ("Modo " + Plasmoid.activeModeName + " activo")
                                        : (Plasmoid.dndActive ? "No Molestar activo" : "Modos de Concentración")
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.8
                                    font.bold: true
                                    color: root.foreground
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: root.hasActiveTimer
                                        ? ("Finaliza en " + Plasmoid.remainingFormatted)
                                        : (root.hasActiveMode ? "Sin temporizador límite" : "Silencia notificaciones y personaliza tu entorno")
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.62
                                    color: root.hasActiveTimer ? root.accent : root.dim
                                    elide: Text.ElideRight
                                }
                            }

                            // Large live timer badge when active
                            Rectangle {
                                visible: root.hasActiveTimer
                                radius: CachyTheme.spacingSmall
                                color: CachyPalette.windowBackground
                                border.width: 1
                                border.color: root.accent
                                implicitWidth: timerBadgeRow.implicitWidth + CachyTheme.spacingMedium * 1.6
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
                                        isMask: true
                                        color: root.accent
                                    }

                                    QQC2.Label {
                                        text: Plasmoid.remainingFormatted
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.72
                                        font.bold: true
                                        font.family: "monospace"
                                        color: root.accent
                                    }
                                }
                            }
                        }

                        // Quick duration pills: 15m, 25m, 45m, 60m, ∞
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: CachyTheme.spacingSmall

                            Repeater {
                                model: [
                                    { label: "15m", minutes: 15 },
                                    { label: "25m", minutes: 25 },
                                    { label: "45m", minutes: 45 },
                                    { label: "60m", minutes: 60 },
                                    { label: "∞", minutes: 0 }
                                ]

                                delegate: Rectangle {
                                    id: pillCard
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Kirigami.Units.gridUnit * 1.45
                                    Layout.preferredHeight: implicitHeight
                                    radius: CachyTheme.spacingSmall
                                    readonly property bool isSelectedDuration: {
                                        if (!root.hasActiveMode) {
                                            return false;
                                        }
                                        if (pillCard.modelData.minutes === 0) {
                                            return !root.hasActiveTimer;
                                        }
                                        const minsLeft = Math.ceil(Plasmoid.remainingSeconds / 60);
                                        return Math.abs(minsLeft - pillCard.modelData.minutes) <= 1;
                                    }
                                    color: pillCard.isSelectedDuration
                                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                                        : CachyPalette.windowBackground
                                    border.width: 1
                                    border.color: pillCard.isSelectedDuration
                                        ? root.accent
                                        : CachyPalette.specularBorder

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: pillCard.modelData.label
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.62
                                        font.bold: pillCard.isSelectedDuration
                                        color: pillCard.isSelectedDuration ? root.accent : root.foreground
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!root.hasActiveMode) {
                                                Plasmoid.activateMode("work", pillCard.modelData.minutes);
                                            } else {
                                                Plasmoid.startCustomTimer(pillCard.modelData.minutes);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. 2x2 Grid of Focus Mode Cards (Trabajo, Personal, Lectura, Descanso)
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: CachyTheme.spacingMedium
                    columnSpacing: CachyTheme.spacingMedium

                    Repeater {
                        model: Plasmoid.modes

                        delegate: Rectangle {
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
                            Layout.minimumHeight: Kirigami.Units.gridUnit * 8.5
                            radius: CachyTheme.radiusSmall
                            color: modeCard.isCurrent
                                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                                : CachyPalette.cardBackground
                            border.width: 1
                            border.color: modeCard.isCurrent
                                ? root.accent
                                : CachyPalette.specularBorder

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: CachyTheme.spacingMedium
                                spacing: CachyTheme.spacingSmall

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: CachyTheme.spacingSmall

                                    Kirigami.Icon {
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                        source: modeCard.modeIcon
                                        isMask: true
                                        color: modeCard.isCurrent ? root.accent : root.foreground
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Active indicator dot
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: modeCard.isCurrent ? root.accent : "transparent"
                                        border.width: 1
                                        border.color: modeCard.isCurrent ? root.accent : CachyPalette.specularBorder
                                    }
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: modeCard.modeName
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.76
                                    font.bold: true
                                    color: modeCard.isCurrent ? root.accent : root.foreground
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: Kirigami.Units.gridUnit * 1.2
                                    text: modeCard.modeSubtitle
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.58
                                    color: root.dim
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: Kirigami.Units.gridUnit * 0.9
                                    spacing: CachyTheme.spacingSmall

                                    QQC2.Label {
                                        text: modeCard.defaultMins > 0 ? (modeCard.defaultMins + " min") : "Manual"
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.54
                                        color: root.dim
                                    }

                                    Item { Layout.fillWidth: true }

                                    QQC2.Label {
                                        visible: modeCard.isCurrent
                                        text: "Activo"
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.54
                                        font.bold: true
                                        color: root.accent
                                    }
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
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: footerCol.implicitHeight + CachyTheme.spacingMedium * 1.6
                    Layout.preferredHeight: implicitHeight
                    radius: CachyTheme.spacingSmall
                    color: (Plasmoid.dndActive && !root.hasActiveMode)
                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                        : CachyPalette.cardBackground
                    border.width: 1
                    border.color: (Plasmoid.dndActive && !root.hasActiveMode)
                        ? root.accent
                        : CachyPalette.specularBorder

                    ColumnLayout {
                        id: footerCol
                        anchors.fill: parent
                        anchors.margins: CachyTheme.spacingMedium
                        spacing: CachyTheme.spacingSmall

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: CachyTheme.spacingMedium

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                source: Plasmoid.dndActive
                                    ? "notifications-disabled"
                                    : "preferences-desktop-notification-bell"
                                color: Plasmoid.dndActive ? root.accent : root.dim
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: "No Molestar (DND)"
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.72
                                    font.bold: true
                                    color: root.foreground
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: Plasmoid.dndActive
                                        ? "Notificaciones emergentes silenciadas"
                                        : "Notificaciones del sistema permitidas"
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.58
                                    color: root.dim
                                    elide: Text.ElideRight
                                }
                            }

                            QQC2.Switch {
                                checked: Plasmoid.dndActive
                                onToggled: {
                                    Plasmoid.dndActive = checked;
                                }
                            }
                        }

                        // "Desactivar Concentración" button when a mode is active
                        Rectangle {
                            visible: root.hasActiveMode
                            Layout.fillWidth: true
                            implicitHeight: Kirigami.Units.gridUnit * 1.85
                            Layout.preferredHeight: implicitHeight
                            radius: CachyTheme.spacingSmall
                            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                            border.width: 1
                            border.color: root.accent

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: CachyTheme.spacingSmall

                                Kirigami.Icon {
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                    source: "dialog-cancel"
                                    isMask: true
                                    color: root.accent
                                }

                                QQC2.Label {
                                    text: "Desactivar Concentración"
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.68
                                    font.bold: true
                                    color: root.accent
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
