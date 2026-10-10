# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

TARGET = harbour-dollfin

CONFIG += sailfishapp

SOURCES += src/harbour-dollfin.cpp

include(src/core/core.pri)

DISTFILES += \
    qml/harbour-dollfin.qml \
    qml/cover/CoverPage.qml \
    qml/pages/TodayPage.qml \
    rpm/$${TARGET}.spec \
    translations/*.ts \
    $${TARGET}.desktop

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
TRANSLATIONS += \
    translations/$${TARGET}-nl.ts \
    translations/$${TARGET}-nb.ts
