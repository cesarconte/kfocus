/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#pragma once

#include "focuscontroller.h"
#include <Plasma/Applet>
#include <QVariantList>

class FocusApplet : public Plasma::Applet
{
    Q_OBJECT

    Q_PROPERTY(FocusController *controller READ controller CONSTANT)
    Q_PROPERTY(QVariantList modes READ modes NOTIFY modesChanged)
    Q_PROPERTY(QString activeModeId READ activeModeId NOTIFY activeModeChanged)
    Q_PROPERTY(QString activeModeName READ activeModeName NOTIFY activeModeChanged)
    Q_PROPERTY(QString activeModeIcon READ activeModeIcon NOTIFY activeModeChanged)
    Q_PROPERTY(bool dndActive READ dndActive WRITE setDndActive NOTIFY dndChanged)
    Q_PROPERTY(int remainingSeconds READ remainingSeconds NOTIFY timerChanged)
    Q_PROPERTY(QString remainingFormatted READ remainingFormatted NOTIFY timerChanged)

public:
    explicit FocusApplet(QObject *parent, const KPluginMetaData &data, const QVariantList &args);
    ~FocusApplet() override;

    void init() override;

    FocusController *controller() const;
    QVariantList modes() const;
    QString activeModeId() const;
    QString activeModeName() const;
    QString activeModeIcon() const;
    bool dndActive() const;
    void setDndActive(bool enabled);
    int remainingSeconds() const;
    QString remainingFormatted() const;

    Q_INVOKABLE void activateMode(const QString &modeId, int durationMinutes = -1);
    Q_INVOKABLE void deactivateMode();
    Q_INVOKABLE void toggleMode(const QString &modeId);
    Q_INVOKABLE void startCustomTimer(int minutes);
    Q_INVOKABLE void updateModeConfig(const QString &modeId, bool dnd, int defaultMinutes, const QString &colorScheme);
    Q_INVOKABLE void toggleDnd();

Q_SIGNALS:
    void modesChanged();
    void activeModeChanged();
    void dndChanged();
    void timerChanged();

private:
    FocusController *m_controller = nullptr;
};
