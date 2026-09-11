# Basic Center — SDDM Theme

Tema SDDM simples e limpo:

- login centralizado;
- data e hora acima dos campos;
- seleção de sessão/desktop na parte inferior;
- wallpaper configurável por caminho no `theme.conf`;
- compatível com SDDM/Qt 6.

## Alterar o wallpaper

Edite:

`theme.conf`

e altere:

`Background=/caminho/para/sua/imagem.jpg`

Exemplo:

`Background=/home/seu_usuario/Imagens/wallpaper.jpg`

Também funciona com PNG/JPEG e outros formatos suportados pelo Qt.

## Instalar

Copie a pasta para:

`/usr/share/sddm/themes/basic-center`

Depois configure o SDDM:

```ini
[Theme]
Current=basic-center
```

Isso pode ficar em `/etc/sddm.conf` ou em um arquivo dentro de `/etc/sddm.conf.d/`.

## Testar sem reiniciar o computador

Em sistemas com SDDM Qt6:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/basic-center
```

Em algumas distribuições o executável é `sddm-greeter`:

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/basic-center
```

## Observação

O seletor inferior é para escolher a **sessão/desktop** (Plasma, GNOME, XFCE, Hyprland etc.). O SDDM em si é o display manager.
