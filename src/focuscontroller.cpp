/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "focuscontroller.h"

#include <QDateTime>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>

FocusController::FocusController(const QString &configDir, bool enableSystemEffects, QObject *parent)
    : QObject(parent)
    , m_configDir(configDir.trimmed().isEmpty()
                      ? (QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/kfocus"))
                      : configDir)
    , m_systemEffectsEnabled(enableSystemEffects)
    , m_countdownTimer(new QTimer(this))
{
    QDir().mkpath(m_configDir);

    m_countdownTimer->setInterval(1000);
    connect(m_countdownTimer, &QTimer::timeout, this, &FocusController::onCountdownTick);

    loadOrInitializeModes();
    writeActiveModeStatus();

    if (m_systemEffectsEnabled) {
        QDBusConnection bus = QDBusConnection::sessionBus();
        if (bus.isConnected()) {
            bus.registerService(QStringLiteral("org.cesar.kfocus"));
            bus.registerObject(QStringLiteral("/KFocus"),
                               this,
                               QDBusConnection::ExportScriptableContents | QDBusConnection::ExportAllProperties
                                   | QDBusConnection::ExportAllInvokables | QDBusConnection::ExportAllSignals);
        }
    }
}

FocusController::~FocusController()
{
    if (m_systemEffectsEnabled && m_inhibitCookie != 0) {
        applySystemDnd(false);
    }
}

QVariantList FocusController::modes() const
{
    return m_modes;
}

QString FocusController::activeModeId() const
{
    return m_activeModeId;
}

QString FocusController::activeModeName() const
{
    return m_activeModeName;
}

QString FocusController::activeModeIcon() const
{
    return m_activeModeIcon;
}

bool FocusController::dndActive() const
{
    return m_dndActive;
}

int FocusController::remainingSeconds() const
{
    return m_remainingSeconds;
}

QString FocusController::remainingFormatted() const
{
    return formatSeconds(m_remainingSeconds);
}

QString FocusController::configDir() const
{
    return m_configDir;
}

QString FocusController::modesFilePath() const
{
    return m_configDir + QStringLiteral("/modes.json");
}

QString FocusController::stateFilePath() const
{
    return m_configDir + QStringLiteral("/state.json");
}

QString FocusController::activeModeFilePath() const
{
    return m_configDir + QStringLiteral("/active_mode.json");
}

QString FocusController::formatSeconds(int seconds)
{
    const int clamped = qMax(0, seconds);
    const int mins = clamped / 60;
    const int secs = clamped % 60;
    return QStringLiteral("%1:%2")
        .arg(mins, 2, 10, QLatin1Char('0'))
        .arg(secs, 2, 10, QLatin1Char('0'));
}

int FocusController::findModeIndex(const QString &modeId) const
{
    for (int i = 0; i < m_modes.size(); ++i) {
        const QVariantMap map = m_modes.at(i).toMap();
        if (map.value(QStringLiteral("id")).toString() == modeId) {
            return i;
        }
    }
    return -1;
}

void FocusController::loadOrInitializeModes()
{
    QFile f(modesFilePath());
    if (f.exists() && f.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        f.close();
        if (doc.isArray() && !doc.array().isEmpty()) {
            m_modes = doc.array().toVariantList();
            return;
        }
    }

    auto makeMode = [](const QString &id,
                       const QString &name,
                       const QString &icon,
                       bool dnd,
                       int defaultTimerMinutes,
                       const QString &colorScheme,
                       const QString &subtitle) -> QVariantMap {
        QVariantMap m;
        m[QStringLiteral("id")] = id;
        m[QStringLiteral("name")] = name;
        m[QStringLiteral("icon")] = icon;
        m[QStringLiteral("dnd")] = dnd;
        m[QStringLiteral("defaultTimerMinutes")] = defaultTimerMinutes;
        m[QStringLiteral("colorScheme")] = colorScheme;
        m[QStringLiteral("subtitle")] = subtitle;
        return m;
    };

    m_modes = {
        makeMode(QStringLiteral("work"),
                 QStringLiteral("Trabajo"),
                 QStringLiteral("view-pim-tasks"),
                 true,
                 45,
                 QStringLiteral(""),
                 QStringLiteral("Silencia distracciones y activa Pomodoro")),
        makeMode(QStringLiteral("personal"),
                 QStringLiteral("Personal"),
                 QStringLiteral("user-identity"),
                 true,
                 0,
                 QStringLiteral(""),
                 QStringLiteral("Tiempo libre sin notificaciones de trabajo")),
        makeMode(QStringLiteral("reading"),
                 QStringLiteral("Lectura"),
                 QStringLiteral("accessories-dictionary"),
                 true,
                 30,
                 QStringLiteral(""),
                 QStringLiteral("Lectura profunda sin interrupciones")),
        makeMode(QStringLiteral("sleep"),
                 QStringLiteral("Descanso"),
                 QStringLiteral("weather-clear-night"),
                 true,
                 0,
                 QStringLiteral("BreezeDark"),
                 QStringLiteral("Modo oscuro y silencio total"))
    };

    saveModes();
}

void FocusController::saveModes() const
{
    QDir().mkpath(m_configDir);
    QFile f(modesFilePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        const QJsonArray arr = QJsonArray::fromVariantList(m_modes);
        f.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
        f.close();
    }
}

void FocusController::savePreviousStateSnapshot()
{
    m_savedPrevDnd = m_dndActive;
    m_savedPrevColorScheme = queryCurrentColorScheme();

    QJsonObject obj;
    obj[QStringLiteral("previousDndActive")] = m_savedPrevDnd;
    obj[QStringLiteral("previousColorScheme")] = m_savedPrevColorScheme;
    obj[QStringLiteral("savedAt")] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    QDir().mkpath(m_configDir);
    QFile f(stateFilePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
        f.close();
    }
}

void FocusController::restorePreviousStateSnapshot()
{
    bool prevDnd = m_savedPrevDnd;
    QString prevScheme = m_savedPrevColorScheme;

    QFile f(stateFilePath());
    if (f.exists() && f.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        f.close();
        if (doc.isObject()) {
            const QJsonObject obj = doc.object();
            prevDnd = obj.value(QStringLiteral("previousDndActive")).toBool(false);
            prevScheme = obj.value(QStringLiteral("previousColorScheme")).toString();
        }
    }

    if (!m_appliedColorScheme.isEmpty() && !prevScheme.isEmpty() && prevScheme != m_appliedColorScheme) {
        applySystemColorScheme(prevScheme);
    }
    m_appliedColorScheme.clear();

    if (m_dndActive != prevDnd) {
        m_dndActive = prevDnd;
        applySystemDnd(m_dndActive);
        Q_EMIT dndChanged();
    } else if (!prevDnd && m_inhibitCookie != 0) {
        applySystemDnd(false);
    }
}

void FocusController::writeActiveModeStatus() const
{
    QJsonObject obj;
    obj[QStringLiteral("active")] = !m_activeModeId.isEmpty();
    obj[QStringLiteral("modeId")] = m_activeModeId;
    obj[QStringLiteral("modeName")] = m_activeModeName;
    obj[QStringLiteral("modeIcon")] = m_activeModeIcon;
    obj[QStringLiteral("dndActive")] = m_dndActive;
    obj[QStringLiteral("remainingSeconds")] = m_remainingSeconds;
    obj[QStringLiteral("remainingFormatted")] = remainingFormatted();
    obj[QStringLiteral("updatedAt")] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    QDir().mkpath(m_configDir);
    QFile f(activeModeFilePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
        f.close();
    }
}

void FocusController::activateMode(const QString &modeId, int durationMinutes)
{
    const int idx = findModeIndex(modeId);
    if (idx < 0) {
        return;
    }

    if (m_activeModeId.isEmpty()) {
        savePreviousStateSnapshot();
    }

    const QVariantMap mode = m_modes.at(idx).toMap();
    const QString newName = mode.value(QStringLiteral("name")).toString();
    const QString newIcon = mode.value(QStringLiteral("icon")).toString();
    const bool newDnd = mode.value(QStringLiteral("dnd"), true).toBool();
    const int defaultMins = mode.value(QStringLiteral("defaultTimerMinutes")).toInt(0);
    const QString targetScheme = mode.value(QStringLiteral("colorScheme")).toString().trimmed();

    const int effectiveMinutes = (durationMinutes >= 0) ? durationMinutes : defaultMins;

    const bool modeDiff = (m_activeModeId != modeId || m_activeModeName != newName || m_activeModeIcon != newIcon);
    m_activeModeId = modeId;
    m_activeModeName = newName;
    m_activeModeIcon = newIcon;

    if (m_dndActive != newDnd || (newDnd && m_inhibitCookie == 0)) {
        m_dndActive = newDnd;
        applySystemDnd(m_dndActive, QStringLiteral("Modo de Concentración: %1").arg(newName));
        Q_EMIT dndChanged();
    }

    if (!targetScheme.isEmpty()) {
        m_appliedColorScheme = targetScheme;
        applySystemColorScheme(targetScheme);
    }

    if (effectiveMinutes > 0) {
        m_remainingSeconds = effectiveMinutes * 60;
        m_countdownTimer->start();
    } else {
        m_countdownTimer->stop();
        m_remainingSeconds = 0;
    }

    writeActiveModeStatus();

    if (modeDiff) {
        Q_EMIT activeModeChanged();
    }
    Q_EMIT timerChanged();
}

void FocusController::deactivateMode()
{
    const bool wasActive = !m_activeModeId.isEmpty();
    const bool hadTimer = (m_remainingSeconds > 0 || m_countdownTimer->isActive());

    m_countdownTimer->stop();
    m_remainingSeconds = 0;

    m_activeModeId.clear();
    m_activeModeName.clear();
    m_activeModeIcon.clear();

    if (wasActive) {
        restorePreviousStateSnapshot();
    } else if (m_dndActive) {
        m_dndActive = false;
        applySystemDnd(false);
        Q_EMIT dndChanged();
    }

    writeActiveModeStatus();

    if (wasActive) {
        Q_EMIT activeModeChanged();
    }
    if (hadTimer || wasActive) {
        Q_EMIT timerChanged();
    }
}

void FocusController::toggleMode(const QString &modeId)
{
    if (m_activeModeId == modeId) {
        deactivateMode();
    } else {
        activateMode(modeId, -1);
    }
}

void FocusController::startCustomTimer(int minutes)
{
    if (minutes <= 0) {
        m_countdownTimer->stop();
        if (m_remainingSeconds != 0) {
            m_remainingSeconds = 0;
            writeActiveModeStatus();
            Q_EMIT timerChanged();
        }
        return;
    }

    if (m_activeModeId.isEmpty()) {
        activateMode(QStringLiteral("work"), minutes);
        return;
    }

    m_remainingSeconds = minutes * 60;
    m_countdownTimer->start();
    writeActiveModeStatus();
    Q_EMIT timerChanged();
}

void FocusController::updateModeConfig(const QString &modeId, bool dnd, int defaultMinutes, const QString &colorScheme)
{
    const int idx = findModeIndex(modeId);
    if (idx < 0) {
        return;
    }

    QVariantMap mode = m_modes.at(idx).toMap();
    mode[QStringLiteral("dnd")] = dnd;
    mode[QStringLiteral("defaultTimerMinutes")] = qMax(0, defaultMinutes);
    mode[QStringLiteral("colorScheme")] = colorScheme.trimmed();
    m_modes[idx] = mode;

    saveModes();
    Q_EMIT modesChanged();

    if (m_activeModeId == modeId) {
        if (m_dndActive != dnd) {
            m_dndActive = dnd;
            applySystemDnd(m_dndActive, QStringLiteral("Modo de Concentración: %1").arg(m_activeModeName));
            Q_EMIT dndChanged();
        }
        if (!colorScheme.trimmed().isEmpty()) {
            m_appliedColorScheme = colorScheme.trimmed();
            applySystemColorScheme(m_appliedColorScheme);
        }
        writeActiveModeStatus();
    }
}

void FocusController::setDndActive(bool enabled)
{
    if (m_dndActive == enabled) {
        return;
    }
    m_dndActive = enabled;
    applySystemDnd(m_dndActive,
                   m_activeModeName.isEmpty()
                       ? QStringLiteral("No Molestar (KFocus)")
                       : QStringLiteral("Modo de Concentración: %1").arg(m_activeModeName));
    writeActiveModeStatus();
    Q_EMIT dndChanged();
}

void FocusController::toggleDnd()
{
    setDndActive(!m_dndActive);
}

void FocusController::setRemainingSecondsForTest(int seconds)
{
    m_remainingSeconds = qMax(0, seconds);
    writeActiveModeStatus();
    Q_EMIT timerChanged();
}

void FocusController::stepTimerOneSecond()
{
    onCountdownTick();
}

void FocusController::onCountdownTick()
{
    if (m_remainingSeconds <= 0) {
        m_countdownTimer->stop();
        return;
    }

    --m_remainingSeconds;
    if (m_remainingSeconds > 0) {
        writeActiveModeStatus();
        Q_EMIT timerChanged();
        return;
    }

    // Timer reached 0: finish focus session
    const QString finishedId = m_activeModeId;
    const QString finishedName = m_activeModeName.isEmpty() ? QStringLiteral("Concentración") : m_activeModeName;
    deactivateMode();
    sendCompletionNotification(finishedName);
    Q_EMIT focusSessionFinished(finishedId, finishedName);
}

void FocusController::applySystemDnd(bool enable, const QString &reason)
{
    if (!m_systemEffectsEnabled) {
        return;
    }

    QDBusInterface notifIface(QStringLiteral("org.freedesktop.Notifications"),
                              QStringLiteral("/org/freedesktop/Notifications"),
                              QStringLiteral("org.freedesktop.Notifications"),
                              QDBusConnection::sessionBus());

    if (enable) {
        if (m_inhibitCookie == 0 && notifIface.isValid()) {
            const QDBusReply<uint> reply = notifIface.call(
                QStringLiteral("Inhibit"),
                QStringLiteral("org.cesar.kfocus"),
                reason.isEmpty() ? QStringLiteral("Modo de Concentración activo") : reason,
                QVariantMap());
            if (reply.isValid()) {
                m_inhibitCookie = reply.value();
            }
        }
        const QString kwrite = QStandardPaths::findExecutable(QStringLiteral("kwriteconfig6"));
        if (!kwrite.isEmpty()) {
            const QString untilIso = QDateTime::currentDateTimeUtc()
                                         .addSecs(m_remainingSeconds > 0 ? m_remainingSeconds : 3600 * 12)
                                         .toString(Qt::ISODate);
            QProcess:: execute(kwrite, {
                QStringLiteral("--file"), QStringLiteral("plasmanotificationsrc"),
                QStringLiteral("--group"), QStringLiteral("DoNotDisturb"),
                QStringLiteral("--key"), QStringLiteral("Until"),
                untilIso
            });
        }
    } else {
        if (m_inhibitCookie != 0 && notifIface.isValid()) {
            notifIface.call(QStringLiteral("UnInhibit"), m_inhibitCookie);
            m_inhibitCookie = 0;
        }
        const QString kwrite = QStandardPaths::findExecutable(QStringLiteral("kwriteconfig6"));
        if (!kwrite.isEmpty()) {
            QProcess::execute(kwrite, {
                QStringLiteral("--file"), QStringLiteral("plasmanotificationsrc"),
                QStringLiteral("--group"), QStringLiteral("DoNotDisturb"),
                QStringLiteral("--key"), QStringLiteral("Until"),
                QStringLiteral("--delete")
            });
        }
    }
}

void FocusController::applySystemColorScheme(const QString &scheme)
{
    if (!m_systemEffectsEnabled || scheme.trimmed().isEmpty()) {
        return;
    }
    const QString applyBin = QStandardPaths::findExecutable(QStringLiteral("plasma-apply-colorscheme"));
    if (!applyBin.isEmpty()) {
        QProcess::startDetached(applyBin, {scheme.trimmed()});
    }
}

QString FocusController::queryCurrentColorScheme() const
{
    if (!m_systemEffectsEnabled) {
        return QStringLiteral("BreezeDark");
    }
    const QString kread = QStandardPaths::findExecutable(QStringLiteral("kreadconfig6"));
    if (!kread.isEmpty()) {
        QProcess proc;
        proc.start(kread, {
            QStringLiteral("--file"), QStringLiteral("kdeglobals"),
            QStringLiteral("--group"), QStringLiteral("General"),
            QStringLiteral("--key"), QStringLiteral("ColorScheme")
        });
        if (proc.waitForFinished(800) && proc.exitCode() == 0) {
            const QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
            if (!out.isEmpty()) {
                return out;
            }
        }
    }
    return QStringLiteral("BreezeDark");
}

void FocusController::sendCompletionNotification(const QString &finishedModeName) const
{
    if (!m_systemEffectsEnabled) {
        return;
    }
    QDBusInterface notifIface(QStringLiteral("org.freedesktop.Notifications"),
                              QStringLiteral("/org/freedesktop/Notifications"),
                              QStringLiteral("org.freedesktop.Notifications"),
                              QDBusConnection::sessionBus());
    if (notifIface.isValid()) {
        notifIface.asyncCall(
            QStringLiteral("Notify"),
            QStringLiteral("KFocus"),
            static_cast<uint>(0),
            QStringLiteral("weather-clear-night"),
            QStringLiteral("Modo de Concentración finalizado"),
            QStringLiteral("La sesión de %1 ha concluido. Se han restaurado las notificaciones.").arg(finishedModeName),
            QStringList(),
            QVariantMap(),
            5000);
    }
}
