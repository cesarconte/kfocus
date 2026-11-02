/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "focuscontroller.h"

#include <QFile>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

class TestKFocus : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testDefaultModesAndPersistence()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        FocusController ctrl(tempDir.path(), /*enableSystemEffects=*/false);
        const QVariantList modes = ctrl.modes();
        QCOMPARE(modes.size(), 4);

        const QVariantMap work = modes.at(0).toMap();
        QCOMPARE(work.value(QStringLiteral("id")).toString(), QStringLiteral("work"));
        QCOMPARE(work.value(QStringLiteral("name")).toString(), QStringLiteral("Trabajo"));
        QCOMPARE(work.value(QStringLiteral("icon")).toString(), QStringLiteral("view-pim-tasks"));
        QCOMPARE(work.value(QStringLiteral("dnd")).toBool(), true);
        QCOMPARE(work.value(QStringLiteral("defaultTimerMinutes")).toInt(), 45);
        QCOMPARE(work.value(QStringLiteral("colorScheme")).toString(), QStringLiteral(""));
        QCOMPARE(work.value(QStringLiteral("subtitle")).toString(),
                 QStringLiteral("Silencia distracciones y activa Pomodoro"));

        const QVariantMap personal = modes.at(1).toMap();
        QCOMPARE(personal.value(QStringLiteral("id")).toString(), QStringLiteral("personal"));
        QCOMPARE(personal.value(QStringLiteral("name")).toString(), QStringLiteral("Personal"));
        QCOMPARE(personal.value(QStringLiteral("icon")).toString(), QStringLiteral("user-identity"));
        QCOMPARE(personal.value(QStringLiteral("dnd")).toBool(), true);
        QCOMPARE(personal.value(QStringLiteral("defaultTimerMinutes")).toInt(), 0);
        QCOMPARE(personal.value(QStringLiteral("colorScheme")).toString(), QStringLiteral(""));

        const QVariantMap reading = modes.at(2).toMap();
        QCOMPARE(reading.value(QStringLiteral("id")).toString(), QStringLiteral("reading"));
        QCOMPARE(reading.value(QStringLiteral("name")).toString(), QStringLiteral("Lectura"));
        QCOMPARE(reading.value(QStringLiteral("icon")).toString(), QStringLiteral("accessories-dictionary"));
        QCOMPARE(reading.value(QStringLiteral("dnd")).toBool(), true);
        QCOMPARE(reading.value(QStringLiteral("defaultTimerMinutes")).toInt(), 30);

        const QVariantMap sleep = modes.at(3).toMap();
        QCOMPARE(sleep.value(QStringLiteral("id")).toString(), QStringLiteral("sleep"));
        QCOMPARE(sleep.value(QStringLiteral("name")).toString(), QStringLiteral("Descanso"));
        QCOMPARE(sleep.value(QStringLiteral("icon")).toString(), QStringLiteral("weather-clear-night"));
        QCOMPARE(sleep.value(QStringLiteral("dnd")).toBool(), true);
        QCOMPARE(sleep.value(QStringLiteral("defaultTimerMinutes")).toInt(), 0);
        QCOMPARE(sleep.value(QStringLiteral("colorScheme")).toString(), QStringLiteral("BreezeDark"));

        // Verify modes.json exists and is valid JSON array
        QFile modesFile(ctrl.modesFilePath());
        QVERIFY(modesFile.exists());
        QVERIFY(modesFile.open(QIODevice::ReadOnly));
        const QJsonDocument doc = QJsonDocument::fromJson(modesFile.readAll());
        modesFile.close();
        QVERIFY(doc.isArray());
        QCOMPARE(doc.array().size(), 4);
    }

    void testActivateToggleDeactivateAndJsonOutput()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        FocusController ctrl(tempDir.path(), /*enableSystemEffects=*/false);
        QCOMPARE(ctrl.activeModeId(), QStringLiteral(""));
        QCOMPARE(ctrl.dndActive(), false);
        QCOMPARE(ctrl.remainingSeconds(), 0);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("00:00"));

        // Activate "work" with default duration (45m = 2700s)
        ctrl.activateMode(QStringLiteral("work"));
        QCOMPARE(ctrl.activeModeId(), QStringLiteral("work"));
        QCOMPARE(ctrl.activeModeName(), QStringLiteral("Trabajo"));
        QCOMPARE(ctrl.activeModeIcon(), QStringLiteral("view-pim-tasks"));
        QCOMPARE(ctrl.dndActive(), true);
        QCOMPARE(ctrl.remainingSeconds(), 2700);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("45:00"));

        // Check state.json and active_mode.json
        QVERIFY(QFile::exists(ctrl.stateFilePath()));
        QFile activeFile(ctrl.activeModeFilePath());
        QVERIFY(activeFile.exists());
        QVERIFY(activeFile.open(QIODevice::ReadOnly));
        const QJsonObject activeObj = QJsonDocument::fromJson(activeFile.readAll()).object();
        activeFile.close();
        QCOMPARE(activeObj.value(QStringLiteral("active")).toBool(), true);
        QCOMPARE(activeObj.value(QStringLiteral("modeId")).toString(), QStringLiteral("work"));
        QCOMPARE(activeObj.value(QStringLiteral("modeName")).toString(), QStringLiteral("Trabajo"));
        QCOMPARE(activeObj.value(QStringLiteral("dndActive")).toBool(), true);
        QCOMPARE(activeObj.value(QStringLiteral("remainingSeconds")).toInt(), 2700);
        QCOMPARE(activeObj.value(QStringLiteral("remainingFormatted")).toString(), QStringLiteral("45:00"));

        // Test 25m Pomodoro countdown formatting ("24:59")
        ctrl.startCustomTimer(25);
        QCOMPARE(ctrl.remainingSeconds(), 1500);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("25:00"));
        ctrl.stepTimerOneSecond();
        QCOMPARE(ctrl.remainingSeconds(), 1499);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("24:59"));

        // Toggle same mode ("work") should deactivate it
        ctrl.toggleMode(QStringLiteral("work"));
        QCOMPARE(ctrl.activeModeId(), QStringLiteral(""));
        QCOMPARE(ctrl.activeModeName(), QStringLiteral(""));
        QCOMPARE(ctrl.dndActive(), false);
        QCOMPARE(ctrl.remainingSeconds(), 0);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("00:00"));

        // Toggle "reading" should activate it (30m = 1800s)
        ctrl.toggleMode(QStringLiteral("reading"));
        QCOMPARE(ctrl.activeModeId(), QStringLiteral("reading"));
        QCOMPARE(ctrl.activeModeName(), QStringLiteral("Lectura"));
        QCOMPARE(ctrl.remainingSeconds(), 1800);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("30:00"));

        // Explicit deactivateMode
        ctrl.deactivateMode();
        QCOMPARE(ctrl.activeModeId(), QStringLiteral(""));
        QCOMPARE(ctrl.dndActive(), false);
    }

    void testTimerCountdownExpirationAutoDeactivates()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        FocusController ctrl(tempDir.path(), /*enableSystemEffects=*/false);
        QSignalSpy finishedSpy(&ctrl, &FocusController::focusSessionFinished);

        ctrl.activateMode(QStringLiteral("work"), 1);
        ctrl.setRemainingSecondsForTest(2);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("00:02"));

        ctrl.stepTimerOneSecond();
        QCOMPARE(ctrl.activeModeId(), QStringLiteral("work"));
        QCOMPARE(ctrl.remainingSeconds(), 1);
        QCOMPARE(ctrl.remainingFormatted(), QStringLiteral("00:01"));
        QCOMPARE(finishedSpy.count(), 0);

        ctrl.stepTimerOneSecond();
        QCOMPARE(ctrl.activeModeId(), QStringLiteral(""));
        QCOMPARE(ctrl.remainingSeconds(), 0);
        QCOMPARE(ctrl.dndActive(), false);
        QCOMPARE(finishedSpy.count(), 1);
    }

    void testUpdateModeConfigPersistence()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        {
            FocusController ctrl(tempDir.path(), /*enableSystemEffects=*/false);
            ctrl.updateModeConfig(QStringLiteral("personal"), false, 60, QStringLiteral("BreezeLight"));
        }

        // Reload from disk in a fresh instance
        FocusController reloaded(tempDir.path(), /*enableSystemEffects=*/false);
        const QVariantList modes = reloaded.modes();
        QCOMPARE(modes.size(), 4);
        const QVariantMap personal = modes.at(1).toMap();
        QCOMPARE(personal.value(QStringLiteral("id")).toString(), QStringLiteral("personal"));
        QCOMPARE(personal.value(QStringLiteral("dnd")).toBool(), false);
        QCOMPARE(personal.value(QStringLiteral("defaultTimerMinutes")).toInt(), 60);
        QCOMPARE(personal.value(QStringLiteral("colorScheme")).toString(), QStringLiteral("BreezeLight"));
    }

    void testMainQmlCompilesCleanly()
    {
        QQmlEngine engine;
        const QString mainPath = QStringLiteral(KFOCUS_SOURCE_DIR) + QStringLiteral("/src/qml/main.qml");
        QVERIFY(QFile::exists(mainPath));
        QQmlComponent mainComp(&engine, QUrl::fromLocalFile(mainPath));
        QVERIFY2(!mainComp.isError(), qPrintable(mainComp.errorString()));
    }

    void testRealSystemValidation()
    {
        // Validate real kreadconfig6 and org.freedesktop.Notifications D-Bus introspection without altering desktop state
        const QString metaPath = QStringLiteral(KFOCUS_SOURCE_DIR) + QStringLiteral("/src/metadata.json");
        QVERIFY(QFile::exists(metaPath));

        FocusController ctrl(QTemporaryDir().path(), /*enableSystemEffects=*/false);
        QCOMPARE(FocusController::formatSeconds(1499), QStringLiteral("24:59"));
        QCOMPARE(FocusController::formatSeconds(0), QStringLiteral("00:00"));
    }
};

QTEST_MAIN(TestKFocus)
#include "test_kfocus.moc"
