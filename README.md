# KFocus — Modos de Concentración (macOS Focus Modes) para KDE Plasma 6

**KFocus** (`org.cesar.kfocus`) es un applet nativo de **KDE Plasma 6.8 + Wayland** con estética **Liquid Glass** que replica los **Modos de Concentración (Focus Modes)** del Centro de Control de macOS (*Trabajo*, *Personal*, *Lectura*, *Descanso*), integrándose con el sistema de notificaciones de KDE Plasma, los esquemas de color y otros componentes del ecosistema (`kisland`, `kiri`).

---

## Características principales

- **4 Perfiles de Concentración preconfigurados y personalizables (`~/.config/kfocus/modes.json`)**:
  - **Trabajo (`work`)**: Silencia distracciones (DND) e inicia automáticamente un temporizador Pomodoro de 45 minutos.
  - **Personal (`personal`)**: Silencia notificaciones sin límite de tiempo para desconectar del trabajo.
  - **Lectura (`reading`)**: Silencia interrupciones durante sesiones de lectura profunda de 30 minutos.
  - **Descanso (`sleep`)**: Activa el silencio total (DND) y aplica el esquema de color oscuro (`BreezeDark`).
- **Restauración automática de estado (`~/.config/kfocus/state.json`)**:
  - Al activar cualquier modo, guarda una instantánea del estado previo de *No Molestar* y del esquema de color activo en KDE Plasma, restaurándolos fielmente al finalizar o desactivar el modo.
- **Integración nativa con No Molestar (Do Not Disturb)**:
  - Invoca `org.freedesktop.Notifications.Inhibit` por D-Bus manteniendo la cookie de inhibición activa y sincroniza `plasmanotificationsrc` (`DoNotDisturb` -> `Until`).
- **Temporizador de Concentración / Pomodoro integrado**:
  - Píldoras rápidas (`15m`, `25m`, `45m`, `60m`, `∞`) con cuenta atrás en vivo en el panel y notificación de escritorio al concluir la sesión.
- **Estado compartido para KIsland y Kiri (`~/.config/kfocus/active_mode.json` y D-Bus `org.cesar.kfocus`)**:
  - Expone el modo activo, icono, estado DND y tiempo restante tanto en disco como en el bus de sesión D-Bus (`/KFocus`).

---

## Requisitos

- CachyOS / Arch Linux con **KDE Plasma 6.8+** (Wayland)
- Qt 6.7+ (`Core`, `DBus`, `Gui`, `Qml`, `Quick`, `Test`)
- KDE Frameworks 6 (`ECM`, `Config`, `CoreAddons`, `I18n`, `Plasma`, `PlasmaQuick`)
- Herramientas CLI de KDE Plasma (`kwriteconfig6`, `kreadconfig6`, `plasma-apply-colorscheme`)

---

## Compilación, pruebas e instalación

```bash
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local -DBUILD_TESTING=ON
cmake --build build -j$(nproc)
ctest --test-dir build --output-on-failure
cmake --install build
```

---

## Uso

1. Añade el widget **KFocus** a tu panel de KDE Plasma (clic derecho en el panel -> *Añadir o gestionar widgets...* -> buscar **KFocus**).
2. Haz clic izquierdo en la píldora **KFocus** para desplegar el centro de **Modos de Concentración** con estética Liquid Glass, o haz clic central sobre la píldora para alternar rápidamente *No Molestar* / desactivar el modo actual.
3. Consulta el estado activo desde otros scripts o applets en `~/.config/kfocus/active_mode.json` o mediante D-Bus en `org.cesar.kfocus` (`/KFocus`).

---

## Limitaciones conocidas

- El filtrado selectivo por aplicación individual (listas blancas por app dentro de DND) depende de las capacidades del servidor `org.freedesktop.Notifications` de KDE Plasma, por lo que el modo *No Molestar* inhibe globalmente las notificaciones emergentes no críticas mientras el perfil está activo.
