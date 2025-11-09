Deprecated

Nota: el instalador principal `archtools.sh` realiza automáticamente una reinstalación limpia de Firefox (elimina variantes y perfiles; instala `firefox` estable).

## Reinstalar Firefox (limpio)

Script para desinstalar completamente Firefox (y variantes), limpiar perfiles/cachés y reinstalar.

Uso básico (Arch/pacman):

```
tools/reinstall-firefox.sh
```

Opciones:
- `--esr` reinstala `firefox-esr`
- `--dev` reinstala `firefox-developer-edition`
- `--flatpak` reinstala `org.mozilla.Firefox` (Flatpak)
- `--snap` reinstala `firefox` (Snap)
- `--aur <pkg>` reinstala paquete AUR (requiere `yay` o `paru`)

Ejemplos:

```
tools/reinstall-firefox.sh --esr
tools/reinstall-firefox.sh --flatpak
tools/reinstall-firefox.sh --aur firefox-nightly
```