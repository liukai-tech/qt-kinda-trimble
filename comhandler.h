#ifndef COMHANDLER_H
#define COMHANDLER_H

#include "kinda_trimble_shared.h"

#include <QSerialPort>
#include <QSerialPortInfo>
#include <QThread>
#include "converter.h"
#include "qbytehelper.h"
#include "qmldatahelper.h"
#include <QQuickView>
#include <QQuickItem>
#include "cmdbuilder.h"

class COMHandler : public QThread
{
    Q_OBJECT
public:
    static void finishCOM();
    void receiveReport();
    void run();

    void (COMHandler::*methodToStartThreadWith)();
    static QString name;
    static QSerialPort *com;
    static QByteArray readedData;
    static quint8 previouslyReadedChar;
    static QList<QSerialPortInfo> portsList;

signals:
    void appendReceivedText(QVariant s);
    void newValuesGained(QVariant nx, QVariant ny);
public slots:
    void send_command(int, int);
    void readFromCOM();
    void configureCOM(int, int, int, int, int, int);
    void getSerialPortsList();
};
#include "packetparser.h"

#endif // COMHANDLER_H
