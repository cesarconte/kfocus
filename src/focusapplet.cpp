/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "focusapplet.h"
#include "focuscontroller.h"

#include <KPluginFactory>

K_PLUGIN_CLASS_WITH_JSON(FocusApplet, "metadata.json")

FocusApplet::FocusApplet(QObject *parent, const KPluginMetaData &data, const QVariantList &args)
    : Plasma::Applet(parent, data, args)
    , m_controller(new FocusController(QString(), true, this))
{
    connect(m_controller, &FocusController::modesChanged, this, &FocusApplet::modesChanged);
    connect(m_controller, &FocusController::activeModeChanged, this, &FocusApplet::activeModeChanged);
    connect(m_controller, &FocusController::dndChanged, this, &FocusApplet::dndChanged);
    connect(m_controller, &FocusController::timerChanged, this, &FocusApplet::timerChanged);
}

FocusApplet::~FocusApplet() = default;

void FocusApplet::init()
{
    Plasma::Applet::init();
}

FocusController *FocusApplet::controller() const
{
    return m_controller;
}

QVariantList FocusApplet::modes() const
{
    return m_controller->modes();
}

QString FocusApplet::activeModeId() const
{
    return m_controller->activeModeId();
}

QString FocusApplet::activeModeName() const
{
    return m_controller->activeModeName();
}

QString FocusApplet::activeModeIcon() const
{
    return m_controller->activeModeIcon();
}

bool FocusApplet::dndActive() const
{
    return m_controller->dndActive();
}

void FocusApplet::setDndActive(bool enabled)
{
    m_controller->setDndActive(enabled);
}

int FocusApplet::remainingSeconds() const
{
    return m_controller->remainingSeconds();
}

QString FocusApplet::remainingFormatted() const
{
    return m_controller->remainingFormatted();
}

void FocusApplet::activateMode(const QString &modeId, int durationMinutes)
{
    m_controller->activateMode(modeId, durationMinutes);
}

void FocusApplet::deactivateMode()
{
    m_controller->deactivateMode();
}

void FocusApplet::toggleMode(const QString &modeId)
{
    m_controller->toggleMode(modeId);
}

void FocusApplet::startCustomTimer(int minutes)
{
    m_controller->startCustomTimer(minutes);
}

void FocusApplet::updateModeConfig(const QString &modeId, bool dnd, int defaultMinutes, const QString &colorScheme)
{
    m_controller->updateModeConfig(modeId, dnd, defaultMinutes, colorScheme);
}

void FocusApplet::toggleDnd()
{
    m_controller->toggleDnd();
}

#include "focusapplet.moc"
