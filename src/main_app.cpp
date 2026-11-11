/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "focuscontroller.h"

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kfocus"));
    app.setApplicationDisplayName(QStringLiteral("Focus — Modos de Concentración"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("focus-symbolic"), QIcon::fromTheme(QStringLiteral("preferences-system-time"))));

    QCommandLineParser parser;
    parser.addHelpOption();
    QCommandLineOption screenshotOpt(QStringLiteral("screenshot"),
                                     QStringLiteral("Capture window screenshot and exit"),
                                     QStringLiteral("path"));
    parser.addOption(screenshotOpt);
    parser.process(app);

    FocusController controller;

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/home/cesar/.local/lib/qt6/qml"));
    engine.rootContext()->setContextProperty(QStringLiteral("FocusCtrl"), &controller);
    engine.load(QUrl(QStringLiteral("qrc:/org/cesar/kfocus/qml/FocusWindow.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    if (parser.isSet(screenshotOpt)) {
        if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
            const QString outPath = parser.value(screenshotOpt);
            QTimer::singleShot(350, win, [win, outPath, &app]() {
                const QImage img = win->grabWindow();
                img.save(outPath);
                app.quit();
            });
        }
    }

    return app.exec();
}
