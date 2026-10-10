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
    // Must match [X-Sailjail] in the .desktop so AppDataLocation is the
    // sandbox-provided private dir (~/.local/share/org.dollfin/Dollfin).
    application->setOrganizationName(QStringLiteral("org.dollfin"));
    application->setApplicationName(QStringLiteral("Dollfin"));
    application->setApplicationVersion(QStringLiteral("1.0"));

    const QString dataDir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);

    dollfin::AppController controller(dataDir + QStringLiteral("/settings.ini"));
    QString error;
    if (!controller.initialize(dataDir + QStringLiteral("/dollfin.db"), &error))
        qWarning() << "dollfin: failed to open database:" << error;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("app"), &controller);
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-dollfin.qml")));
    view->show();

    return application->exec();
}
