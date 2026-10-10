TARGET = tst_core
TEMPLATE = app
QT += core sql
QT -= gui
CONFIG += console c++11
CONFIG -= app_bundle

INCLUDEPATH += ../../src
include(../../src/core/core.pri)

SOURCES += tst_core.cpp
