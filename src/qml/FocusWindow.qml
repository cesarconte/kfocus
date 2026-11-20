/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: root

    title: "Focus — Modos de Concentración"
    width: 780
    height: 540
    minimumWidth: 660
    minimumHeight: 460
    visible: true

    showTrafficLights: true
    showTitleBarDivider: true
    showWindowFrame: true
    sidebarVisible: true
    sidebarWidth: 224
    cornerRadius: CachyTheme.radiusWindow

    readonly property var ctrl: typeof FocusCtrl !== "undefined" ? FocusCtrl : null
    readonly property bool hasActiveMode: Boolean(ctrl && ctrl.activeModeId.length > 0)
    readonly property bool hasActiveTimer: Boolean(ctrl && ctrl.remainingSeconds > 0)

    function modeColor(modeId: string): color {
        if (modeId === "work") return "#007AFF";
        if (modeId === "personal") return "#AF52DE";
        if (modeId === "reading") return "#FF9500";
        if (modeId === "sleep") return "#32ADE6";
        return CachyTheme.accentColor;
    }

    function modeIcon(modeId: string): string {
        if (modeId === "work") return "applications-office";
        if (modeId === "personal") return "user-identity";
        if (modeId === "reading") return "accessories-dictionary";
        if (modeId === "sleep") return "weather-clear-night";
        return "weather-clear-night";
    }

    // =========================================================================
    // 1. GOLDEN GATE EDGE-TO-EDGE FOCUS SIDEBAR
    // =========================================================================
    sidebar: [
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 12
            spacing: 4

            Text {
                Layout.leftMargin: 8
                Layout.bottomMargin: 4
                text: i18n("Modos de Concentración")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: CachyTheme.textMuted
            }

            Repeater {
                model: root.ctrl ? root.ctrl.modes : []

                CachySidebarItem {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.name || ""
                    iconName: root.modeIcon(modelData.id || "")
                    iconColor: root.modeColor(modelData.id || "")
                    squircleIconBadge: true
                    badgeText: (root.ctrl && root.ctrl.activeModeId === modelData.id) ? "ON" : ""
                    selected: Boolean(root.ctrl && root.ctrl.activeModeId === modelData.id)
                    onClicked: {
                        if (root.ctrl) {
                            root.ctrl.toggleMode(modelData.id);
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Bottom Do Not Disturb (DND) Card in Sidebar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: dndSidebarRow.implicitHeight + 18
                radius: CachyTheme.radiusMedium
                color: CachyTheme.cardBackground
                border.width: 1
                border.color: (root.ctrl && root.ctrl.dndActive) ? "#AF52DE" : CachyPalette.specularBorder

                RowLayout {
                    id: dndSidebarRow
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: 6
                        color: "#AF52DE"

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "weather-clear-night"
                            size: 14
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: i18n("No Molestar")
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: CachyTheme.textPrimary
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (root.ctrl && root.ctrl.dndActive) ? i18n("Silenciado") : i18n("Inactivo")
                            font.pixelSize: 10
                            color: (root.ctrl && root.ctrl.dndActive) ? "#AF52DE" : CachyTheme.textMuted
                            elide: Text.ElideRight
                        }
                    }

                    CachySwitch {
                        checked: Boolean(root.ctrl && root.ctrl.dndActive)
                        onToggled: {
                            if (root.ctrl) {
                                root.ctrl.setDndActive(checked);
                            }
                        }
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 2. GOLDEN GATE 44PX HEADER TOOLBAR
    // =========================================================================
    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            CachyToolbarButton {
                visible: root.hasActiveMode
                text: i18n("Desactivar")
                implicitWidth: 84
                tooltipText: i18n("Desactivar modo de concentración actual")
                onClicked: {
                    if (root.ctrl) {
                        root.ctrl.deactivateMode();
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 3. MAIN FOCUS DASHBOARD (Active Timer + 2x2 Focus Cards)
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // Top Active Focus Status & Quick Pomodoro Duration Pills Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: topFocusCol.implicitHeight + 28
                radius: 16
                color: CachyTheme.cardBackground
                border.width: 1
                border.color: root.hasActiveMode ? CachyTheme.accentColor : CachyPalette.specularBorder

                ColumnLayout {
                    id: topFocusCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 12
                            color: root.hasActiveMode ? root.modeColor(root.ctrl.activeModeId) : CachyTheme.surfacePill

                            CachyIcon {
                                anchors.centerIn: parent
                                name: root.hasActiveMode ? root.modeIcon(root.ctrl.activeModeId) : "weather-clear-night"
                                size: 22
                                color: root.hasActiveMode ? "#FFFFFF" : CachyTheme.textPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: root.hasActiveMode
                                    ? i18n("Modo %1 activo", root.ctrl.activeModeName)
                                    : ((root.ctrl && root.ctrl.dndActive) ? i18n("No Molestar activo") : i18n("Modos de Concentración"))
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                color: CachyTheme.textPrimary
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.hasActiveTimer
                                    ? i18n("Finaliza en %1", root.ctrl.remainingFormatted)
                                    : (root.hasActiveMode ? i18n("Sin temporizador límite") : i18n("Silencia notificaciones y personaliza tu sesión en KDE Plasma 6"))
                                font.pixelSize: 12
                                color: root.hasActiveTimer ? CachyTheme.accentColor : CachyTheme.textSecondary
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: root.hasActiveTimer
                            height: 32
                            implicitWidth: timerText.implicitWidth + 20
                            radius: 16
                            color: CachyTheme.withAlpha(CachyTheme.accentColor, 0.16)
                            border.width: 1
                            border.color: CachyTheme.accentColor

                            Text {
                                id: timerText
                                anchors.centerIn: parent
                                text: root.ctrl ? root.ctrl.remainingFormatted : "00:00"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                font.family: "monospace"
                                color: CachyTheme.accentColor
                            }
                        }
                    }

                    // Quick Duration Pills: 15m, 25m, 45m, 60m, Sin límite
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { label: "15m", minutes: 15 },
                                { label: "25m (Pomodoro)", minutes: 25 },
                                { label: "45m", minutes: 45 },
                                { label: "60m", minutes: 60 },
                                { label: i18n("Sin límite"), minutes: 0 }
                            ]

                            Rectangle {
                                id: durPill
                                required property var modelData
                                Layout.fillWidth: true
                                height: 32
                                radius: 16

                                readonly property bool isSelectedDuration: {
                                    if (!root.hasActiveMode) return false;
                                    if (durPill.modelData.minutes === 0) return !root.hasActiveTimer;
                                    const minsLeft = Math.ceil(root.ctrl.remainingSeconds / 60);
                                    return Math.abs(minsLeft - durPill.modelData.minutes) <= 1;
                                }

                                color: isSelectedDuration ? CachyTheme.accentColor : CachyTheme.surfacePill
                                border.width: 1
                                border.color: isSelectedDuration ? CachyTheme.accentColor : CachyPalette.specularBorder

                                Text {
                                    anchors.centerIn: parent
                                    text: durPill.modelData.label
                                    font.pixelSize: 11
                                    font.weight: durPill.isSelectedDuration ? Font.Bold : Font.Medium
                                    color: durPill.isSelectedDuration ? "#FFFFFF" : CachyTheme.textPrimary
                                    elide: Text.ElideRight
                                }

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        if (!root.ctrl) return;
                                        if (!root.hasActiveMode) {
                                            root.ctrl.activateMode("work", durPill.modelData.minutes);
                                        } else {
                                            root.ctrl.startCustomTimer(durPill.modelData.minutes);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 2x2 Grid of Focus Mode Cards (Trabajo, Personal, Lectura, Descanso)
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 12

                Repeater {
                    model: root.ctrl ? root.ctrl.modes : []

                    Rectangle {
                        id: modeCard
                        required property var modelData
                        readonly property string modeId: modelData.id || ""
                        readonly property bool isCurrent: Boolean(root.ctrl && root.ctrl.activeModeId === modeId)

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: isCurrent
                            ? CachyTheme.withAlpha(root.modeColor(modeId), CachyTheme.isDark ? 0.24 : 0.14)
                            : CachyTheme.cardBackground
                        border.width: isCurrent ? 1.5 : 1
                        border.color: isCurrent ? root.modeColor(modeId) : CachyPalette.specularBorder

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (root.ctrl) {
                                    root.ctrl.toggleMode(modeCard.modeId);
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: root.modeColor(modeCard.modeId)

                                    CachyIcon {
                                        anchors.centerIn: parent
                                        name: root.modeIcon(modeCard.modeId)
                                        size: 20
                                        color: "#FFFFFF"
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: modeCard.modelData.name || ""
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: CachyTheme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: (modeCard.modelData.defaultTimerMinutes || 0) > 0
                                            ? i18n("%1 min por defecto", modeCard.modelData.defaultTimerMinutes)
                                            : i18n("Activación manual")
                                        font.pixelSize: 11
                                        color: CachyTheme.textMuted
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    height: 22
                                    implicitWidth: stateLbl.implicitWidth + 14
                                    radius: 11
                                    color: modeCard.isCurrent ? root.modeColor(modeCard.modeId) : CachyTheme.surfacePill

                                    Text {
                                        id: stateLbl
                                        anchors.centerIn: parent
                                        text: modeCard.isCurrent ? i18n("ACTIVO") : i18n("Activar")
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: modeCard.isCurrent ? "#FFFFFF" : CachyTheme.textSecondary
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: modeCard.modelData.subtitle || ""
                                font.pixelSize: 12
                                color: CachyTheme.textSecondary
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                            }
                        }
                    }
                }
            }
        }
    ]
}
