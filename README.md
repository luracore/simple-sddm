# Basic Center — SDDM Theme

Tema SDDM simples e limpo:

## Baixar:
```bash
cd ~/
git clone https://github.com/luracore/simple-sddm
```

## Instalar:
```bash
sudo rm -rf /usr/share/sddm/themes/simple-sddm
sudo cp -a ~/simple-sddm /usr/share/sddm/themes/simple-sddm
```

##Personalizar o wallpaper

Substitua o arquivo:

```bash
~/simple-sddm/wallpaper.png
```

pela imagem que deseja utilizar.

Depois, realize novamente a etapa da instalação para copiar o novo wallpaper para o diretório do SDDM.

## Configurar SDDM:

Em `/etc/sddm.conf` coloque:

```ini
[Theme]
Current=simple-sddm
```

## Testar sem reiniciar o computador

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/simple-sddm
```
