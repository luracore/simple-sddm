import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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

    Image {
        anchors.fill: parent

        source: config.Background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false

        onStatusChanged: {
            if (status === Image.Error)
                visible = false
        }
    }

    // Escurece levemente o wallpaper para manter o login legível.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.28
    }

    ColumnLayout {
        id: loginArea

        anchors.centerIn: parent
        width: Math.min(360, root.width * 0.82)
        spacing: 12

        // Relógio
        Text {
            Layout.fillWidth: true

            text: Qt.formatTime(new Date(), config.TimeFormat)

            color: root.textColor
            font.pixelSize: Math.max(32, root.height * 0.055)
            font.weight: Font.Light

            horizontalAlignment: Text.AlignHCenter
        }

        // Data
        Text {
            id: dateText

            Layout.fillWidth: true

            color: root.secondaryTextColor
            font.pixelSize: 16

            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            Layout.preferredHeight: 18
        }

        // Usuário
        TextField {
            id: userField

            Layout.fillWidth: true
            implicitHeight: 48

            placeholderText: "Usuário"

            color: root.textColor
            placeholderTextColor: "#999999"

            leftPadding: 16
            rightPadding: 16

            font.pixelSize: 15

            background: Rectangle {
                radius: 8

                color: root.fieldColor
                opacity: 0.92

                border.color: userField.activeFocus
                              ? root.accentColor
                              : "#444444"

                border.width: 1
            }

            Keys.onReturnPressed: {
                passwordField.forceActiveFocus()
            }
        }

        // Senha
        TextField {
            id: passwordField

            Layout.fillWidth: true
            implicitHeight: 48

            placeholderText: "Senha"

            echoMode: TextInput.Password

            color: root.textColor
            placeholderTextColor: "#999999"

            leftPadding: 16
            rightPadding: 16

            font.pixelSize: 15

            background: Rectangle {
                radius: 8

                color: root.fieldColor
                opacity: 0.92

                border.color: passwordField.activeFocus
                              ? root.accentColor
                              : "#444444"

                border.width: 1
            }

            Keys.onReturnPressed: {
                login()
            }
        }

        // Botão Entrar
        Button {
            id: loginButton

            Layout.fillWidth: true
            implicitHeight: 46

            text: "Entrar"

            font.pixelSize: 15

            contentItem: Text {
                text: loginButton.text

                color: "#111111"
                font: loginButton.font

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8

                color: loginButton.down
                       ? "#cccccc"
                       : root.accentColor
            }

            onClicked: {
                login()
            }
        }

        // Mensagem de erro
        Text {
            id: errorText

            Layout.fillWidth: true

            visible: text.length > 0

            text: ""

            color: "#ff7777"
            font.pixelSize: 13

            horizontalAlignment: Text.AlignHCenter

            wrapMode: Text.WordWrap
        }
    }

    // Seletor de sessão/desktop na parte inferior.
    //
    // O ponto importante aqui é que o ComboBox usa o próprio
    // índice da sessionModel. Esse índice será passado para
    // sddm.login().
    Rectangle {
        id: sessionBar

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28

        width: Math.min(300, root.width * 0.7)
        height: 42

        radius: 8

        color: root.panelColor
        opacity: 0.94

        border.color: "#444444"
        border.width: 1

        ComboBox {
            id: sessionBox

            anchors.fill: parent
            anchors.margins: 2

            model: sessionModel

            textRole: "name"

            // Mantém a última sessão utilizada pelo SDDM.
            currentIndex: sessionModel.lastIndex

            background: Rectangle {
                radius: 7
                color: "transparent"
            }

            contentItem: Text {
                leftPadding: 14
                rightPadding: 35

                text: sessionBox.displayText === ""
                      ? "Escolher sessão"
                      : sessionBox.displayText

                color: root.textColor

                font.pixelSize: 14

                verticalAlignment: Text.AlignVCenter
            }

            indicator: Text {
                x: sessionBox.width - width - 12
                y: (sessionBox.height - height) / 2

                text: "▼"

                color: root.secondaryTextColor

                font.pixelSize: 10
            }

            popup: Popup {
                y: sessionBox.height + 4

                width: sessionBox.width

                padding: 4

                background: Rectangle {
                    radius: 8

                    color: root.panelColor

                    border.color: "#555555"
                    border.width: 1
                }

                contentItem: ListView {
                    clip: true

                    implicitHeight: Math.min(
                        contentHeight,
                        260
                    )

                    model: sessionBox.popup.visible
                           ? sessionBox.delegateModel
                           : null

                    currentIndex: sessionBox.highlightedIndex

                    ScrollIndicator.vertical: ScrollIndicator {}
                }
            }

            delegate: ItemDelegate {
                width: sessionBox.width - 8
                height: 38

                highlighted: sessionBox.highlightedIndex === index

                background: Rectangle {
                    radius: 5

                    color: highlighted
                           ? root.accentColor
                           : root.panelColor
                }

                contentItem: Text {
                    text: model.name

                    color: highlighted
                           ? "#111111"
                           : root.textColor

                    leftPadding: 10
                    rightPadding: 10

                    verticalAlignment: Text.AlignVCenter

                    elide: Text.ElideRight
                }

                onClicked: {
                    sessionBox.currentIndex = index
                    sessionBox.popup.close()
                }
            }
        }
    }

    // Atualiza relógio e data a cada segundo.
    Timer {
        interval: 1000

        running: true
        repeat: true

        triggeredOnStart: true

        onTriggered: {
            var now = new Date()

            dateText.text = Qt.formatDateTime(
                now,
                config.DateFormat
            )
        }
    }

    // =========================================================
    // LOGIN
    // =========================================================
    //
    // IMPORTANTE:
    //
    // sddm.login() espera:
    //
    //     login(usuario, senha, sessionIndex)
    //
    // Portanto NÃO passamos o nome da sessão.
    // Passamos sessionBox.currentIndex.
    //
    function login() {

        // Verifica usuário
        if (userField.text.length === 0) {
            errorText.text = "Digite o usuário."

            userField.forceActiveFocus()

            return
        }

        // Verifica se existem sessões
        if (sessionModel.count === 0) {
            errorText.text = "Nenhuma sessão disponível."

            return
        }

        // Verifica o índice selecionado
        if (sessionBox.currentIndex < 0 ||
            sessionBox.currentIndex >= sessionModel.count) {

            errorText.text = "Selecione uma sessão."

            sessionBox.forceActiveFocus()

            return
        }

        // Índice da sessão selecionada.
        var sessionIndex = sessionBox.currentIndex

        errorText.text = ""

        // Login usando o ÍNDICE da sessão.
        sddm.login(
            userField.text,
            passwordField.text,
            sessionIndex
        )
    }

    // Trata falha no login.
    Connections {
        target: sddm

        function onLoginFailed() {
            errorText.text = "Usuário ou senha incorretos."

            passwordField.selectAll()

            passwordField.forceActiveFocus()
        }
    }

    // =========================================================
    // INICIALIZAÇÃO
    // =========================================================

    Component.onCompleted: {

        if (config.ForceLastUser &&
            userModel.lastIndex >= 0) {

            userField.text = userModel.data(
                userModel.index(
                    userModel.lastIndex,
                    0
                ),
                Qt.UserRole + 1
            )

            passwordField.forceActiveFocus()

        } else {

            userField.forceActiveFocus()
        }
    }
}
