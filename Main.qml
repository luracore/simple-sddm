import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import Qt.labs.folderlistmodel

Rectangle {
    id: root

    width: Screen.width
    height: Screen.height

    color: config.BackgroundColor

    property color textColor: config.TextColor
    property color secondaryTextColor: config.SecondaryTextColor
    property color panelColor: config.PanelColor
    property color fieldColor: config.FieldColor
    property color accentColor: config.AccentColor
    property color buttonTextColor: config.stringValue("ButtonTextColor") || "#111111"
    property color borderColor: config.stringValue("BorderColor") || "#444444"
    property color placeholderColor: config.stringValue("PlaceholderColor") || "#999999"
    property color errorColor: config.stringValue("ErrorColor") || "#ff7777"

    // Sem Scale no theme.conf, os tamanhos em px são pensados para 1080 px de altura.
    readonly property real s: config.realValue("Scale") > 0
        ? config.realValue("Scale")
        : Math.max(0.85, Math.min(3, root.height / 1080))

    readonly property real blurAmount: Math.max(0, Math.min(100, config.intValue("Blur"))) / 100

    property bool loginInProgress: false

    // O greeter roda com o idioma do sistema, que pode não ser o mesmo do tema.
    readonly property var locale: config.stringValue("Locale") !== ""
        ? Qt.locale(config.stringValue("Locale"))
        : Qt.locale()

    readonly property string wallpaperFolder: config.stringValue("WallpaperFolder")

    property url wallpaperSource: wallpaperFolder === "" ? config.Background : ""

    FolderListModel {
        id: wallpaperFiles

        folder: root.wallpaperFolder === "" ? "" : Qt.resolvedUrl(root.wallpaperFolder)
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        showDirs: false

        onStatusChanged: {
            if (status === FolderListModel.Ready && root.wallpaperSource.toString() === "")
                root.pickWallpaper();
        }
    }

    // Garantia caso o FolderListModel não chegue a ficar Ready.
    Timer {
        interval: 800
        running: root.wallpaperFolder !== ""
        onTriggered: {
            if (root.wallpaperSource.toString() === "")
                root.wallpaperSource = config.Background;
        }
    }

    function pickWallpaper() {
        // Se a pasta não existir, o FolderListModel lista o diretório atual do
        // processo. Só aceita arquivos que estejam de fato dentro da pasta.
        var base = Qt.resolvedUrl(root.wallpaperFolder).toString().replace(/\/?$/, "/");
        var candidates = [];

        for (var i = 0; i < wallpaperFiles.count; i++) {
            var file = wallpaperFiles.get(i, "fileUrl").toString();
            if (file.indexOf(base) === 0)
                candidates.push(file);
        }

        root.wallpaperSource = candidates.length > 0
            ? candidates[Math.floor(Math.random() * candidates.length)]
            : config.Background;
    }

    Image {
        id: wallpaper

        // Sobra nas bordas para o desfoque não escurecer os cantos.
        anchors.fill: parent
        anchors.margins: root.blurAmount > 0 ? -64 : 0

        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false

        // Com desfoque ativo, quem desenha é o MultiEffect.
        visible: root.blurAmount === 0 && status !== Image.Error
    }

    MultiEffect {
        anchors.fill: wallpaper

        source: wallpaper
        visible: root.blurAmount > 0 && wallpaper.status === Image.Ready

        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: root.blurAmount
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.28
    }

    Item {
        id: ui

        anchors.fill: parent
        opacity: 0

        ColumnLayout {
            id: loginArea

            anchors.centerIn: parent
            width: Math.min(360 * root.s, root.width * 0.82)
            spacing: 12 * root.s

            // Translate em vez de x/y porque anchors.centerIn trava a posição.
            transform: Translate {
                id: loginShift
                y: 20 * root.s
            }

            Text {
                id: clockText

                Layout.fillWidth: true

                color: root.textColor
                font.pixelSize: Math.max(32, root.height * 0.055)
                font.weight: Font.Light

                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                id: dateText

                Layout.fillWidth: true

                color: root.secondaryTextColor
                font.pixelSize: 16 * root.s

                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                Layout.preferredHeight: 18 * root.s
            }

            TextField {
                id: userField

                Layout.fillWidth: true
                implicitHeight: 48 * root.s

                placeholderText: "Usuário"

                color: root.textColor
                placeholderTextColor: root.placeholderColor

                leftPadding: 16 * root.s
                rightPadding: 16 * root.s

                font.pixelSize: 15 * root.s

                background: Rectangle {
                    radius: 8 * root.s

                    color: root.fieldColor
                    opacity: 0.92

                    border.color: userField.activeFocus ? root.accentColor : root.borderColor
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }
                }

                // onAccepted cobre Enter e Return (teclado numérico incluso).
                onAccepted: {
                    passwordField.forceActiveFocus();
                }
            }

            TextField {
                id: passwordField

                property bool revealed: false

                Layout.fillWidth: true
                implicitHeight: 48 * root.s

                placeholderText: "Senha"

                echoMode: revealed ? TextInput.Normal : TextInput.Password

                color: root.textColor
                placeholderTextColor: root.placeholderColor

                leftPadding: 16 * root.s
                rightPadding: revealToggle.width + 20 * root.s

                font.pixelSize: 15 * root.s

                background: Rectangle {
                    radius: 8 * root.s

                    color: root.fieldColor
                    opacity: 0.92

                    border.color: passwordField.activeFocus ? root.accentColor : root.borderColor
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }
                }

                // MouseArea em vez de Button para não roubar o foco do campo.
                Text {
                    id: revealToggle

                    anchors.right: parent.right
                    anchors.rightMargin: 14 * root.s
                    anchors.verticalCenter: parent.verticalCenter

                    text: passwordField.revealed ? "Ocultar" : "Mostrar"

                    color: revealMouse.containsMouse ? root.textColor : root.secondaryTextColor
                    font.pixelSize: 12 * root.s

                    MouseArea {
                        id: revealMouse

                        anchors.fill: parent
                        anchors.margins: -8 * root.s

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: passwordField.revealed = !passwordField.revealed
                    }
                }

                onAccepted: {
                    login();
                }
            }

            // opacity em vez de visible: o espaço fica reservado e o formulário não pula.
            Text {
                id: capsLockText

                Layout.fillWidth: true

                opacity: keyboard.capsLock ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                text: "Caps Lock ativado"

                color: root.secondaryTextColor
                font.pixelSize: 13 * root.s

                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                id: loginButton

                Layout.fillWidth: true
                implicitHeight: 46 * root.s

                text: root.loginInProgress ? "Entrando..." : "Entrar"

                enabled: !root.loginInProgress

                font.pixelSize: 15 * root.s

                contentItem: Text {
                    text: loginButton.text

                    color: root.buttonTextColor
                    font: loginButton.font

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 8 * root.s

                    color: root.accentColor
                    opacity: loginButton.down || !loginButton.enabled ? 0.7 : 1.0

                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                }

                onClicked: {
                    login();
                }
            }

            // Altura fixa, mesmo vazia, para o formulário não pular.
            Text {
                id: errorText

                Layout.fillWidth: true
                Layout.preferredHeight: capsLockText.implicitHeight

                text: ""

                color: root.errorColor
                font.pixelSize: 13 * root.s

                horizontalAlignment: Text.AlignHCenter

                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: sessionBar

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 28 * root.s

            width: Math.min(300 * root.s, root.width * 0.7)
            height: 42 * root.s

            radius: 8 * root.s

            color: root.panelColor
            opacity: 0.94

            border.color: root.borderColor
            border.width: 1

            ComboBox {
                id: sessionBox

                anchors.fill: parent
                anchors.margins: 2

                model: sessionModel

                textRole: "name"

                currentIndex: sessionModel.lastIndex

                background: Rectangle {
                    radius: 7 * root.s
                    color: "transparent"
                }

                contentItem: Text {
                    leftPadding: 14 * root.s
                    rightPadding: 35 * root.s

                    text: sessionBox.displayText === "" ? "Escolher sessão" : sessionBox.displayText

                    color: root.textColor

                    font.pixelSize: 14 * root.s

                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: Text {
                    x: sessionBox.width - width - 12 * root.s
                    y: (sessionBox.height - height) / 2

                    text: "▼"

                    color: root.secondaryTextColor

                    font.pixelSize: 10 * root.s
                }

                popup: Popup {
                    y: sessionBox.height + 4 * root.s

                    width: sessionBox.width

                    padding: 4 * root.s

                    background: Rectangle {
                        radius: 8 * root.s

                        color: root.panelColor

                        border.color: root.borderColor
                        border.width: 1
                    }

                    contentItem: ListView {
                        clip: true

                        implicitHeight: Math.min(contentHeight, 260 * root.s)

                        model: sessionBox.popup.visible ? sessionBox.delegateModel : null

                        currentIndex: sessionBox.highlightedIndex

                        ScrollIndicator.vertical: ScrollIndicator {}
                    }
                }

                delegate: ItemDelegate {
                    width: sessionBox.width - 8 * root.s
                    height: 38 * root.s

                    highlighted: sessionBox.highlightedIndex === index

                    background: Rectangle {
                        radius: 5 * root.s

                        color: highlighted ? root.accentColor : root.panelColor
                    }

                    contentItem: Text {
                        text: model.name

                        color: highlighted ? root.buttonTextColor : root.textColor
                        font.pixelSize: 14 * root.s

                        leftPadding: 10 * root.s
                        rightPadding: 10 * root.s

                        verticalAlignment: Text.AlignVCenter

                        elide: Text.ElideRight
                    }

                    onClicked: {
                        sessionBox.currentIndex = index;
                        sessionBox.popup.close();
                    }
                }
            }
        }

        // Os layouts vêm da config X11 (ex.: localectl set-x11-keymap br,us).
        Button {
            id: layoutButton

            readonly property var layouts: keyboard.layouts
            readonly property bool hasLayouts: layouts && layouts.length > 0
            readonly property var current: hasLayouts ? layouts[keyboard.currentLayout] : null

            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 24 * root.s
            anchors.bottomMargin: 24 * root.s

            visible: hasLayouts

            focusPolicy: Qt.NoFocus

            implicitHeight: 40 * root.s
            implicitWidth: Math.max(56 * root.s, layoutLabel.implicitWidth + 24 * root.s)

            ToolTip.visible: hovered && current !== null
            ToolTip.text: current ? current.longName : ""
            ToolTip.delay: 500

            contentItem: Text {
                id: layoutLabel

                text: layoutButton.current ? layoutButton.current.shortName.toUpperCase() : ""

                color: root.textColor
                font.pixelSize: 13 * root.s

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 9 * root.s
                color: layoutButton.hovered ? "#55333333" : "#33222222"

                border.width: 1
                border.color: "#66ffffff"
            }

            onClicked: {
                if (layouts.length > 1)
                    keyboard.currentLayout = (keyboard.currentLayout + 1) % layouts.length;
            }
        }

        Row {
            id: powerButtons

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 24 * root.s

            spacing: 10 * root.s
            z: 10

            Repeater {
                model: {
                    var actions = [];

                    if (sddm.canSuspend)
                        actions.push({ label: "Suspender", action: "suspend" });
                    if (sddm.canHibernate)
                        actions.push({ label: "Hibernar", action: "hibernate" });
                    if (sddm.canReboot)
                        actions.push({ label: "Reiniciar", action: "reboot" });
                    if (sddm.canPowerOff)
                        actions.push({ label: "Desligar", action: "powerOff" });

                    return actions;
                }

                delegate: Button {
                    id: powerButton

                    required property var modelData

                    text: modelData.label

                    focusPolicy: Qt.NoFocus

                    implicitWidth: 112 * root.s
                    implicitHeight: 40 * root.s

                    font.pixelSize: 13 * root.s

                    contentItem: Text {
                        text: powerButton.text
                        font: powerButton.font
                        color: root.textColor

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 9 * root.s
                        color: powerButton.down ? root.accentColor : powerButton.hovered ? "#55333333" : "#33222222"

                        border.width: 1
                        border.color: powerButton.down ? root.accentColor : "#66ffffff"

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }
                    }

                    onClicked: {
                        if (modelData.action === "suspend")
                            sddm.suspend();
                        else if (modelData.action === "hibernate")
                            sddm.hibernate();
                        else if (modelData.action === "reboot")
                            sddm.reboot();
                        else if (modelData.action === "powerOff")
                            sddm.powerOff();
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: introAnim

        NumberAnimation {
            target: ui
            property: "opacity"
            from: 0
            to: 1
            duration: 450
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: loginShift
            property: "y"
            from: 20 * root.s
            to: 0
            duration: 450
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: shakeAnim

        readonly property real d: 10 * root.s

        NumberAnimation { target: loginShift; property: "x"; to: -shakeAnim.d; duration: 45 }
        NumberAnimation { target: loginShift; property: "x"; to: shakeAnim.d; duration: 70 }
        NumberAnimation { target: loginShift; property: "x"; to: -shakeAnim.d * 0.6; duration: 60 }
        NumberAnimation { target: loginShift; property: "x"; to: shakeAnim.d * 0.6; duration: 60 }
        NumberAnimation { target: loginShift; property: "x"; to: 0; duration: 45 }
    }

    Timer {
        interval: 1000

        running: true
        repeat: true

        triggeredOnStart: true

        onTriggered: {
            var now = new Date();

            clockText.text = root.locale.toString(now, config.TimeFormat);
            dateText.text = root.locale.toString(now, config.DateFormat);
        }
    }

    function login() {
        if (root.loginInProgress)
            return;

        if (userField.text.length === 0) {
            errorText.text = "Digite o usuário.";

            userField.forceActiveFocus();
            shakeAnim.restart();

            return;
        }

        if (sessionBox.count === 0) {
            errorText.text = "Nenhuma sessão disponível.";

            return;
        }

        if (sessionBox.currentIndex < 0 || sessionBox.currentIndex >= sessionBox.count) {
            errorText.text = "Selecione uma sessão.";

            sessionBox.forceActiveFocus();

            return;
        }

        var sessionIndex = sessionBox.currentIndex;

        errorText.text = "";
        root.loginInProgress = true;

        sddm.login(userField.text, passwordField.text, sessionIndex);
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.loginInProgress = false;

            errorText.text = "Usuário ou senha incorretos.";

            passwordField.text = "";
            passwordField.revealed = false;
            passwordField.forceActiveFocus();

            shakeAnim.restart();
        }
    }

    Component.onCompleted: {
        // config.ForceLastUser seria a string "false", que é truthy.
        if (config.boolValue("ForceLastUser") && userModel.lastUser !== "") {
            userField.text = userModel.lastUser;

            passwordField.forceActiveFocus();
        } else {
            userField.forceActiveFocus();
        }

        introAnim.start();
    }
}
