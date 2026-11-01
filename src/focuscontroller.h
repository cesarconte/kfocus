/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class FocusController : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.cesar.kfocus")

    Q_PROPERTY(QVariantList modes READ modes NOTIFY modesChanged)
    Q_PROPERTY(QString activeModeId READ activeModeId NOTIFY activeModeChanged)
    Q_PROPERTY(QString activeModeName READ activeModeName NOTIFY activeModeChanged)
    Q_PROPERTY(QString activeModeIcon READ activeModeIcon NOTIFY activeModeChanged)
    Q_PROPERTY(bool dndActive READ dndActive WRITE setDndActive NOTIFY dndChanged)
    Q_PROPERTY(int remainingSeconds READ remainingSeconds NOTIFY timerChanged)
    Q_PROPERTY(QString remainingFormatted READ remainingFormatted NOTIFY timerChanged)

public:
    explicit FocusController(const QString &configDir = QString(),
                             bool enableSystemEffects = true,
                             QObject *parent = nullptr);
    ~FocusController() override;

    QVariantList modes() const;
    QString activeModeId() const;
    QString activeModeName() const;
    QString activeModeIcon() const;
    bool dndActive() const;
    int remainingSeconds() const;
    QString remainingFormatted() const;

    QString configDir() const;
    QString modesFilePath() const;
    QString stateFilePath() const;
    QString activeModeFilePath() const;

    Q_INVOKABLE void activateMode(const QString &modeId, int durationMinutes = -1);
    Q_INVOKABLE void deactivateMode();
    Q_INVOKABLE void toggleMode(const QString &modeId);
    Q_INVOKABLE void startCustomTimer(int minutes);
    Q_INVOKABLE void updateModeConfig(const QString &modeId, bool dnd, int defaultMinutes, const QString &colorScheme);
    Q_INVOKABLE void setDndActive(bool enabled);
    Q_INVOKABLE void toggleDnd();

    // Helpers for deterministic unit testing and formatting
    static QString formatSeconds(int seconds);
    void setRemainingSecondsForTest(int seconds);
    void stepTimerOneSecond();

Q_SIGNALS:
    void modesChanged();
    void activeModeChanged();
    void dndChanged();
    void timerChanged();
    void focusSessionFinished(const QString &modeId, const QString &modeName);

private Q_SLOTS:
    void onCountdownTick();

private:
    void loadOrInitializeModes();
    void saveModes() const;
    void savePreviousStateSnapshot();
    void restorePreviousStateSnapshot();
    void writeActiveModeStatus() const;

    void applySystemDnd(bool enable, const QString &reason = QString());
    void applySystemColorScheme(const QString &scheme);
    QString queryCurrentColorScheme() const;
    void sendCompletionNotification(const QString &finishedModeName) const;
    int findModeIndex(const QString &modeId) const;

    QString m_configDir;
    bool m_systemEffectsEnabled = true;

    QVariantList m_modes;
    QString m_activeModeId;
    QString m_activeModeName;
    QString m_activeModeIcon;
    bool m_dndActive = false;
    int m_remainingSeconds = 0;

    bool m_savedPrevDnd = false;
    QString m_savedPrevColorScheme;
    QString m_appliedColorScheme;
    uint m_inhibitCookie = 0;

    QTimer *m_countdownTimer = nullptr;
};
