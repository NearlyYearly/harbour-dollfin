QT += sql
INCLUDEPATH += $$PWD
HEADERS += \
    $$PWD/types.h \
    $$PWD/database.h \
    $$PWD/store.h \
    $$PWD/scheduleengine.h
SOURCES += \
    $$PWD/database.cpp \
    $$PWD/store.cpp \
    $$PWD/scheduleengine.cpp
