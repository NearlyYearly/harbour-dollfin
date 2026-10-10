// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>
#include <QStandardPaths>

#include <sailfishapp.h>

#include "app/appcontroller.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(SailfishApp::application(argc, argv));
    application->setApplicationName(QStringLiteral("harbour-dollfin"));
    application->setOrganizationName(QStringLiteral("org.dollfin"));

    // Sandbox-friendly data location: ~/.local/share/harbour-dollfin/
    const QString dataDir =
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/harbour-dollfin");
    QDir().mkpath(dataDir);

    dollfin::AppController controller;
    QString error;
    if (!controller.initialize(dataDir + QStringLiteral("/dollfin.db"), &error))
        qWarning() << "dollfin: failed to open database:" << error;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("app"), &controller);
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-dollfin.qml")));
    view->show();

    return application->exec();
}
