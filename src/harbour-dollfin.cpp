// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 lillelilje

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>
#include <QStandardPaths>

#include <cstdio>

#include <sailfishapp.h>

#include "app/appcontroller.h"

namespace {

QString g_logFilePath;
QString g_debugFlagPath;
bool g_forceFileLog = false;

// Messages always go to stderr. They are mirrored to a file only when logging
// is explicitly enabled (the `debug` marker file, or DOLLFIN_DEBUG), so a
// release build writes nothing to disk.
void dollfinMessageHandler(QtMsgType type, const QMessageLogContext &, const QString &message)
{
    const char *level = "info";
    switch (type) {
    case QtDebugMsg:    level = "debug"; break;
    case QtInfoMsg:     level = "info"; break;
    case QtWarningMsg:  level = "warning"; break;
    case QtCriticalMsg: level = "critical"; break;
    case QtFatalMsg:    level = "fatal"; break;
    }

    const QString line = QStringLiteral("%1 %2: %3")
                             .arg(QDateTime::currentDateTime().toString(Qt::ISODate),
                                  QString::fromLatin1(level), message);
    std::fprintf(stderr, "%s\n", qPrintable(line));

    if (g_logFilePath.isEmpty())
        return;
    if (!g_forceFileLog && !QFile::exists(g_debugFlagPath))
        return;

    QFile file(g_logFilePath);
    if (file.open(QIODevice::Append | QIODevice::Text)) {
        file.write(line.toUtf8());
        file.write("\n");
    }
}

} // namespace

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(SailfishApp::application(argc, argv));
    // Must match [X-Sailjail] in the .desktop so AppDataLocation is the
    // sandbox-provided private dir (~/.local/share/org.dollfin/Dollfin).
    application->setOrganizationName(QStringLiteral("org.dollfin"));
    application->setApplicationName(QStringLiteral("Dollfin"));

    const QString dataDir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    g_logFilePath = dataDir + QStringLiteral("/dollfin.log");
    g_debugFlagPath = dataDir + QStringLiteral("/debug");
    g_forceFileLog = qEnvironmentVariableIsSet("DOLLFIN_DEBUG");
    qInstallMessageHandler(dollfinMessageHandler);
    qInfo() << "dollfin: data dir" << dataDir;

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
