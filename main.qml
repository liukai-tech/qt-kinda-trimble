import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls 2.2
import QtQml 2.2
import "./" as MyQML

// Главное окно. Такое большое, только потому что содержит все текстовые поля-подписи
// и заготовок под строки с сигналами спутников. В главном окне - интерфейс с важными для оператора значениями,
// получаемыми из пакетов, окно лога, куда печатаются сообщения, кнопка настройки обновления
// информации и настройки подключения к GPS-модулю, и табличка с вкладками, в которой весь функционал
// по отправке пакетов и, соответственно, получению информации и конфигурированию GPS-модуля.

Window {
    id: main_window
    visible: true
    width: 1800
    height: 950
    color: "#ffffff"
    title: qsTr("Kinda Trimble")

    // Всё равно, что соответствующие макросы кодов пакетов в kinda_trimble_shared.h, только для здешних файлов.
    property int _COMMAND_FIRMWARE_INFO                          : 0x1C
    property int     _CMDSUB_FIRMWARE_VERSION                    : 0x01
    property int     _CMDSUB_HARDWARE_COMPONENT_INFO             : 0x03
    property int _COMMAND_INITIATE_RESET                         : 0x1E
    property int _COMMAND_REQEST_SOFTWARE_VERSION                : 0x1F
    property int _COMMAND_REQUEST_GPS_SATELLITES                 : 0x24
    property int _COMMAND_INITIATE_HOT_RESET                     : 0x25
    property int _COMMAND_REQUEST_SIGNAL_LEVELS                  : 0x27
    property int _COMMAND_ACCURATE_INIT_POS_XYZ                  : 0x31
    property int _COMMAND_ACCURATE_INIT_POS_LLA                  : 0x32
    property int _COMMAND_SATELLITE_SELECTION                    : 0x34
    property int _COMMAND_SET_IO_OPTIONS                         : 0x35
    property int _COMMAND_REQUEST_STATUS_AND_POS                 : 0x37
    property int _COMMAND_REQUEST_SATELLITE_SYSTEM_DATA          : 0x38
    property int _COMMAND_SET_REQUEST_SATELLITES_AND_HEALTH      : 0x39
    property int _COMMAND_REQUEST_LAST_RAW_MEASUREMENT           : 0x3A
    property int _COMMAND_REQUEST_SATELLITE_TRACKING_STATUS      : 0x3C
    property int _COMMAND_SET_RECEIVER_CONFIG                    : 0xBB
    property int _COMMAND_SET_PORT_CONFIG                        : 0xBC
    property int _COMMAND_SUPER                                  : 0x8E
    property int     _CMDSUB_SET_PACKET_BROADCAST_MASK           : 0xA5
    property int     _CMDSUB_REQUEST_PRIMARY_TIMING_PACKET       : 0xAB
    property int     _CMDSUB_REQUEST_SUPPL_TIMING_PACKET         : 0xAC

    // Сигнал, который отправляется каждый раз, когда оператор жмет на одну из кнопок, которая подразумевает
    // отправку пакета GPS-модулю. Этот сигнал привязан к слоту в С++, который и формирует и отправляет пакеты.
    // Передается код и подкод, либо код и первый информационный байт (иногда так удобнее).
    signal sig_send_command(int code, int subcode)
    // Сигнал, который вызывается в ответ на сигнал второго окна (оно кидает сигнал при нажатии
    // кнопки открытия порта) и передается в код С++, который и открывает порт. Передаются все настройки порта.
    signal sig_open_port(int portIndex, int baud, int dataBits, int parity, int flowControl, int stopBits)
    // Сигнал, отправляемый в код С++ для того, чтобы он обновил список открытых портов.
    // (список будет прислан непосредственно компоненту, отображающему его, с помощью обращения по объектному имени)
    signal sig_get_serial_ports()

    // Счетчик сообщений в логе.
    property int logCount: 0

    // Слот для сигнала из С++, который вызывается тогда, когда нужно добавить запись в лог.
    function onAppendReceivedtext(s) {
        logCount++;
        // Автоматическое очищение лога при слишком большом количестве накопившихся сообщений.
        if (logCount > 100) {
            receivedText.clear();
            logCount = 0;
        }
        receivedText.append(s+"\n");
    }

    Rectangle {
        id: rectangle
        x: 445
        y: 151
        width: 521
        height: 414
        color: "#00000000"
        border.color: "#a9a9a9"

        ScrollView {
            id: view
            width: 583
            height: 492
            contentWidth: 16
            topPadding: 0
            contentHeight: 30
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.fill: parent

            // Текстовая область - лог ресивера. Обрамлен в ScrollView, чтобы его можно было прокручивать.
            TextArea {
                id: receivedText
                x: -5
                y: -1
                width: 518
                height: 407
                text: ""
                wrapMode: Text.WordWrap
                font.weight: Font.Light
                readOnly: true
                selectByMouse: true
                font.wordSpacing: 0
                font.pixelSize: 14
            }
        }


    }

    // Элемент с вкладками, на которых кнопки для отправки пакетов.
    TabBar {
        id: tabs
        x: 18
        y: 25
        width: 400
        height: 40
        clip: true
        objectName: "tabsMain"

        // Ниже перечислены все заголовки вкладок. Суть в том, что при выборе заголовка
        // меняется параметр y tabs, он называется currentIndex. Ниже есть загрузчик вкладок, он
        // следит за изменением этого параметра.

        TabButton {
            id: essentialsTab
            text: "Основное"
            width: implicitWidth + 15
            //source: "essentials.qml"
        }

        TabButton {
            id: satelliteInfo
            text: "Информация о спутниках"
            width: implicitWidth + 15
           //source: "satellite_info.qml"
        }

        TabButton {
            id: ioOptions
            text: "Опции ввода/вывода"
            width: implicitWidth + 15
            //source: "io_options.qml"
        }

        TabButton {
            id: initPosition
            text: "Начальная позиция"
            width: implicitWidth + 15
            //source: "init_position.qml"
        }

        TabButton {
            id: otherStuff
            text: "Включение и здоровье спутников"
            width: implicitWidth + 15
            //source: "other_stuff.qml"
        }

        TabButton {
            id: autopacketMasking
            text: "Управление авторассылкой"
            width: implicitWidth + 15
            //source: "autopacket_masking.qml"
        }

        TabButton {
            id: timingPackets
            text: "Пакеты по таймингу"
            width: implicitWidth + 15
            //source: "timing_packets.qml"
        }

        onCurrentIndexChanged: {
            // В момент изменения индекса текущей вкладки - подгрузить нужную вкладку.
            // Вкладки представлены файлами-абзацами (Item).
            switch (currentIndex)
            {
            case 0:
                loader.source = "qrc:/essentials.qml"
                break;
            case 1:
                loader.source = "qrc:/satellite_info.qml"
                break;
            case 2:
                loader.source = "qrc:/io_options.qml"
                break;
            case 3:
                loader.source = "qrc:/init_position.qml"
                break;
            case 4:
                loader.source = "qrc:/other_stuff.qml"
                break;
            case 5:
                loader.source = "qrc:/autopacket_masking.qml"
                break;
            case 6:
                loader.source = "qrc:/timing_packets.qml"
                break;
            }
        }
    }

    // Сам загрузчик вкладок. Выше - его использование, здесь - определение.
    Loader {
        id: loader
        x: 18
        y: 65
        source: "qrc:/essentials.qml"
    }

    Text {
        id: text1
        x: 445
        y: 108
        width: 174
        height: 42
        text: qsTr("Область логгирования получаемых данных")
        wrapMode: Text.WordWrap
        font.italic: false
        font.bold: true
        textFormat: Text.RichText
        font.pixelSize: 14
    }

    // Объект окна настройки порта VirtualCOM. В самом файле COMInit.qml - всё равно что определение класса, а здесь - объект этого класса.
    // Окно модальное, чтобы нельзя было работать с основным окном, пока порт не открыт.
    COMInit {
        id: com_init_window
        objectName: "com_init_window"
        modality: Qt.WindowModal

        // Этот сигнал вызывается, НЕ когда окно закрывается - он лишь назван так. Этот сигнал приходит из окна
        // настройки порта, когда оператор щелкает по кнопке "Подключиться". То окно закрывается, а главное - появляется,
        // и отсылается сигнал в среду С++, что нужно открыть порт.
        onCloseWindow: {
            com_init_window.close();
            main_window.show();
            sig_open_port(portIndex, baud, dataBits, parity, flowControl, stopBits);
        }
    }

    // Кнопка открытия окна настройки порта.
    Button {
        id: button
        x: 445
        y: 15
        width: 238
        height: 50
        text: qsTr("Настройка VirtualCOM")
        font.bold: true

        // При нажатии главное окно будет скрыто, а окно настройки - показано.
        // Заодно интерфейс просит сигналом код С++ обновить список открытых портов в интерфейсе окна настройки порта.
        onClicked: {
            sig_get_serial_ports();
            com_init_window.show();
            main_window.hide();
        }
    }

    Label {
        id: temperatureLabel
        objectName: "temperatureLabel"
        x: 10
        y: 900
        text: "Температура, С:"
        font.pointSize: 9
    }

    Rectangle {
        id: rectangle1
        x: 0
        y: 868
        width: 846
        height: 2
        color: "#7d7d7d"
    }

    Label {
        id: latitudePosLabel
        objectName: "latitudePosLabel"
        x: 281
        y: 605
        text: "Широта:"
    }

    Label {
        id: longitudePosLabel
        objectName: "longitudePosLabel"
        x: 281
        y: 625
        text: "Долгота:"
    }

    Label {
        id: altitudePosLabel
        objectName: "altitudePosLabel"
        x: 281
        y: 645
        text: "Высота, м:"
    }

    Text {
        id: text2
        x: 10
        y: 582
        text: qsTr("Спутники и уровни их сигнала")
        textFormat: Text.RichText
        font.pixelSize: 14
        font.italic: false
        font.bold: true
    }

    // Просто экземпляры для отображения уровня сигнала спутников. Их нельзя создавать динамически, поэтому сделаны заготовки.
    // (нужные будут скрыты и изменены из кода С++)

    MyQML.Satellite_status_template {
        id: template1
        objectName: "template1"
        x: 10
        y: 613
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template2
        objectName: "template2"
        x: 10
        y: 633
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template3
        objectName: "template3"
        x: 10
        y: 653
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template4
        objectName: "template4"
        x: 10
        y: 673
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template5
        objectName: "template5"
        x: 10
        y: 693
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template6
        objectName: "template6"
        x: 10
        y: 713
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template7
        objectName: "template7"
        x: 10
        y: 733
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template8
        objectName: "template8"
        x: 10
        y: 753
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template9
        objectName: "template9"
        x: 10
        y: 773
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template10
        objectName: "template10"
        x: 10
        y: 793
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template11
        objectName: "template11"
        x: 10
        y: 813
        visible: false
    }

    MyQML.Satellite_status_template {
        id: template12
        objectName: "template12"
        x: 10
        y: 833
        visible: false
    }

    // Дальше - текстовые записи и подписи, которые с помощью объектного имени получают значения из С++.

    Text {
        id: text3
        x: 282
        y: 582
        text: qsTr("Позиция GPS (LLA)")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: llaPositionBiasLabel
        x: 281
        y: 665
        text: "Погрешность:"
        objectName: "llaPositionBiasLabel"
    }

    Label {
        id: llaPositionFixLabel
        x: 281
        y: 685
        text: "Отметка времени:"
        objectName: "llaPositionFixLabel"
    }

    Label {
        id: xPositionLabel
        x: 281
        y: 748
        text: "X:"
        objectName: "xPositionLabel"
    }

    Label {
        id: yPositionLabel
        x: 281
        y: 768
        text: "Y:"
        objectName: "yPositionLabel"
    }

    Label {
        id: zPositionLabel
        x: 281
        y: 788
        text: "Z:"
        objectName: "zPositionLabel"
    }

    Text {
        id: text4
        x: 281
        y: 725
        text: qsTr("Позиция GPS (XYZ)")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: xyzPositionBiasLabel
        x: 281
        y: 808
        text: "Погрешность:"
        objectName: "xyzPositionBiasLabel"
    }

    Label {
        id: xyzPositionFixLabel
        x: 281
        y: 828
        text: "Отметка времени:"
        objectName: "xyzPositionFixLabel"
    }

    Label {
        id: eastVelocityLabel
        x: 565
        y: 605
        text: "Скорость: восточная:"
        objectName: "eastVelocityLabel"
    }

    Label {
        id: northVelocityLabel
        x: 565
        y: 625
        text: "северная:"
        objectName: "northVelocityLabel"
    }

    Label {
        id: upVelocityLabel
        x: 565
        y: 645
        text: "по высоте:"
        objectName: "upVelocityLabel"
    }

    Text {
        id: text5
        x: 565
        y: 582
        text: qsTr("Скорость GPS (ENU)")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: enuVelocityBiasLabel
        x: 565
        y: 665
        text: "Погрешность:"
        objectName: "enuVelocityBiasLabel"
    }

    Label {
        id: enuVelocityFixLabel
        x: 565
        y: 685
        text: "Отметка времени:"
        objectName: "enuVelocityFixLabel"
    }


    Text {
        id: text6
        x: 565
        y: 725
        text: qsTr("Скорость GPS (XYZ)")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: xVelocityLabel
        x: 565
        y: 748
        text: "X:"
        objectName: "xVelocityLabel"
    }

    Label {
        id: yVelocityLabel
        x: 565
        y: 768
        text: "Y:"
        objectName: "yVelocityLabel"
    }

    Label {
        id: zVelocityLabel
        x: 565
        y: 788
        text: "Z:"
        objectName: "zVelocityLabel"
    }

    Label {
        id: xyzVelocityBiasLabel
        x: 565
        y: 808
        text: "Погрешность:"
        objectName: "xyzVelocityBiasLabel"
    }

    Label {
        id: xyzVelocityFixLabel
        x: 565
        y: 828
        text: "Отметка времени:"
        objectName: "xyzVelocityFixLabel"
    }

    Text {
        id: text7
        x: 859
        y: 582
        text: qsTr("Информация о прошивке:")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: _RPTSUB_FIRMWARE_VERSION_label
        x: 859
        y: 605
        width: 83
        height: 134
        text: "(не получена)"
        objectName: "_RPTSUB_FIRMWARE_VERSION_label"
    }

    Text {
        id: text8
        x: 859
        y: 753
        text: qsTr("Информация о плате:")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: _RPTSUB_HARDWARE_COMPONENT_INFO_label
        x: 859
        y: 776
        width: 230
        height: 161
        text: "(не получена)"
        wrapMode: Text.NoWrap
        objectName: "_RPTSUB_HARDWARE_COMPONENT_INFO_label"
    }

    Text {
        id: text9
        x: 991
        y: 380
        text: qsTr("Информация о ПО платы:")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: _REPORT_SOFTWARE_VERSION_INFO_label
        x: 991
        y: 400
        width: 377
        height: 157
        text: "(не получена)"
        wrapMode: Text.NoWrap
        objectName: "_REPORT_SOFTWARE_VERSION_INFO_label"
    }

    Text {
        id: text10
        x: 1440
        y: 14
        text: qsTr("Текущие настройки ввода-вывода GPS:")
        font.bold: true
        font.pixelSize: 14
        font.italic: false
        textFormat: Text.RichText
    }

    Label {
        id: _REPORT_REQUEST_IO_OPTIONS_label
        x: 1440
        y: 37
        width: 85
        height: 234
        text: "(не получены)"
        objectName: "_REPORT_REQUEST_IO_OPTIONS_label"
    }

    Label {
        id: fixedSVsLabel
        x: 10
        y: 605
        text: "- спутников в фиксе:"
        objectName: "fixedSVsLabel"
    }

    Label {
        id: timeLabel
        x: 10
        y: 876
        text: "Дата и время:"
        font.pointSize: 9
        objectName: "timeLabel"
    }

    Text {
        id: text11
        x: 1219
        y: 753
        text: qsTr("Включение спутников для отслеживания позиции")
        font.pixelSize: 14
        font.bold: true
        textFormat: Text.RichText
        font.italic: false
    }

    Label {
        id: enabledSVsLabel
        x: 1199
        y: 785
        width: 54
        height: 133
        text: "вкл/выкл"
        horizontalAlignment: Text.AlignLeft
        objectName: "enabledSVsLabel"
    }

    Text {
        id: text12
        x: 1194
        y: 582
        text: qsTr("Учет работоспособности спутников для их использования")
        font.pixelSize: 14
        font.bold: true
        textFormat: Text.RichText
        font.italic: false
    }

    Label {
        id: healthEnabledSVsLabel
        x: 1175
        y: 605
        width: 66
        height: 128
        text: "прин/игнор"
        horizontalAlignment: Text.AlignLeft
        objectName: "healthEnabledSVsLabel"
    }

    Text {
        id: text13
        x: 991
        y: 14
        text: qsTr("Состояние GPS-модуля")
        font.pixelSize: 14
        font.bold: true
        textFormat: Text.RichText
        font.italic: false
    }

    Label {
        id: supplInfoLabel
        x: 991
        y: 37
        width: 377
        height: 328
        text: "(не получено)"
        wrapMode: Text.NoWrap
        objectName: "supplInfoLabel"
    }

    Label {
        id: dacVoltageLabel
        x: 10
        y: 924
        text: "Напряжение на ЦАП, В:"
        objectName: "dacVoltageLabel"
        font.pointSize: 9
    }

    Rectangle {
        id: rectangle2
        x: 265
        y: 574
        width: 2
        height: 296
        color: "#7d7d7d"
    }

    Rectangle {
        id: rectangle3
        x: 549
        y: 574
        width: 2
        height: 296
        color: "#7d7d7d"
    }

    Rectangle {
        id: rectangle4
        x: 0
        y: 574
        width: 1800
        height: 2
        color: "#7d7d7d"
    }

    Rectangle {
        id: rectangle5
        x: 844
        y: 574
        width: 2
        height: 376
        color: "#7d7d7d"
    }

    Rectangle {
        id: rectangle6
        x: 1163
        y: 574
        width: 2
        height: 376
        color: "#7d7d7d"
    }

    Rectangle {
        id: rectangle7
        x: 1427
        y: 0
        width: 2
        height: 576
        color: "#7d7d7d"
    }

    Rectangle {
        id: rectangle8
        x: 978
        y: 372
        width: 451
        height: 2
        color: "#7d7d7d"
    }

    Rectangle {
        id: rectangle9
        x: 978
        y: 0
        width: 2
        height: 576
        color: "#7d7d7d"
    }

    // Еще три кнопки настройки авторассылки пакетов. Можно приостановить рассылку (фактически это пакет
    // 0х8F 0xA5 со всеми снятыми галочками), возобновить (просто тот же пакет со всеми установленными галочками)
    // или обновить единоразово (вызывается метод С++ COMHandler::requestEssentialInfo()).

    property bool pausePacketFlow: false;

    Button {
        id: button1
        x: 723
        y: 7
        width: 243
        height: 35
        text: qsTr("Приостановить обновление")
        onClicked: {
            pausePacketFlow = true;
            sig_send_command(_COMMAND_SUPER, _CMDSUB_SET_PACKET_BROADCAST_MASK);
        }
    }

    Button {
        id: button2
        x: 723
        y: 49
        width: 243
        height: 35
        text: qsTr("Возобновить обновление")
        onClicked: {
            pausePacketFlow = false;
            sig_send_command(_COMMAND_SUPER, _CMDSUB_SET_PACKET_BROADCAST_MASK);
        }
    }

    Button {
        id: button3
        x: 723
        y: 89
        width: 243
        height: 35
        text: qsTr("ОБНОВИТЬ ВСЕ")
        font.bold: true
        onClicked: {
            // Специальный код для вызова метода получения всей необходимой информации
            // (в С++ в ответ на код "-42" есть специальная ветвь кода).
            sig_send_command(-42, 0);
        }
    }

    // Проверяется перед тем, как отправить сигнал о логгировании. Если взведен, в лог ничего не отсылается,
    // однако пакеты по-прежнему принимаются, разбираются и обновляют интерфейсные данные.
    CheckBox {
        id: freezeLog
        objectName: "freezeLog"
        x: 652
        y: 115
        text: qsTr("Заморозить лог без остановки обновления")
    }
}