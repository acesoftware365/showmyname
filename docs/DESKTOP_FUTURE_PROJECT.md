# ShowMyName Desktop — Proyecto futuro

## Visión

Crear una versión de escritorio de ShowMyName para preparar, editar, organizar y compartir carteles visuales con una pantalla de trabajo amplia. La versión móvil sigue siendo ideal para mostrar el cartel; la versión de escritorio será el estudio para crearlo con más comodidad.

La idea central es conservar el lenguaje visual actual: fondo oscuro, acento morado, paneles redondeados y una vista previa grande. En una pantalla ancha, el usuario siempre debe ver el resultado a la izquierda y las propiedades a la derecha.

## Layout principal

```text
┌─────────────────────────────────────────────────────────────────────┐
│ ShowMyName                                              Compartir ⚙   │
├──────────────────────────────────────┬──────────────────────────────┤
│                                      │  Propiedades                 │
│                                      │  ┌────────────────────────┐  │
│          CANVAS / PREVIEW            │  │ Capas  1  2  3  +      │  │
│                                      │  │ Deshacer   Rehacer     │  │
│      El usuario crea aquí            │  │ Borrar     Color       │  │
│                                      │  │ Estilo                 │  │
│                                      │  │ Grosor                 │  │
│                                      │  └────────────────────────┘  │
│                                      │                              │
│   [ SHOW ]  [ Compartir imagen ]     │                              │
├─────────────────────────────────────────────────────────────────────┤
│ Airport / Pickup · Concert / Event · ColorWave · Handwriting · Logo │
└─────────────────────────────────────────────────────────────────────┘
```

### Reglas de diseño

- El canvas ocupa todo el espacio disponible de la columna izquierda.
- El panel de propiedades tiene una anchura constante y la misma altura visual que el canvas.
- Si hay más controles de los que caben, el panel hace scroll interno; el layout exterior no crece ni empuja el menú inferior.
- El menú de modos queda fijo abajo en escritorio y muestra todos los modos a la vez.
- En pantallas estrechas, el menú se vuelve horizontal y se mueve automáticamente para dejar visible el modo activo.
- Los botones principales se mantienen debajo del canvas: **SHOW** y **Compartir imagen**.

## Modos de creación

### 1. Airport / Pickup

Propiedades de texto para carteles rápidos de llegada o recogida:

- Texto y emojis.
- Tamaño de texto.
- Negrita, cursiva y subrayado.
- Alineación izquierda, centro o derecha.
- Color de texto y fondo.
- Icono opcional, con símbolos de avión, flechas, taxi y saludo.

### 2. Concert / Event

Herramientas para mensajes de escenario, fiestas y eventos:

- Texto principal.
- Estilos LED, neón, pulso, marquesina y onda.
- Dirección y velocidad de movimiento.
- Color y brillo.
- Efectos de borde, puntos LED y animaciones.
- Vista previa en tiempo real antes de mostrarlo a pantalla completa.

### 3. ColorWave

Carteles de texto que cambian de color:

- Texto y emojis.
- Formato de texto: tamaño, negrita, cursiva, subrayado y alineación.
- Un color fijo o varios colores.
- Añadir, reorganizar y eliminar colores.
- Tiempo por color.
- Transición Fade o Slide.
- Duración de la transición.

### 4. Handwriting

El modo de escritorio debe ser el más visual y directo:

- Canvas grande para escribir o dibujar directamente con mouse, trackpad, lápiz o pantalla táctil.
- Hasta cinco capas.
- Añadir capas con `+` y seleccionar una capa activa.
- Color de tinta por capa.
- Estilos Smooth, Marker, Neon, Chalk y Fire.
- Tamaño de línea.
- Borrar únicamente la capa activa.
- Deshacer y rehacer por pasos.
- Posible siguiente propiedad: opacidad de tinta.
- Posible siguiente propiedad: ocultar o bloquear una capa.

### 5. Logo

Herramientas para crear un cartel visual a partir de imágenes:

- Cargar una imagen o varias imágenes.
- Ver las imágenes guardadas.
- Rotación automática entre imágenes.
- Efectos Fade, Slide y Zoom.
- Tiempo visible de cada imagen.

## Compartir y exportar

Cada modo tendrá un botón de compartir junto a **SHOW**.

- Exporta la creación actual como imagen PNG.
- Comparte el archivo con el panel nativo de macOS o Windows.
- Mantiene el fondo negro y el diseño final, sin los controles de la app.
- Futuro: permitir elegir PNG, JPG, vídeo corto o GIF para animaciones.
- Futuro: selector de tamaño para historias, publicaciones, pantalla horizontal y pantalla vertical.

## Flujo de trabajo en escritorio

1. Elegir un modo desde el menú inferior.
2. Crear o editar directamente en el canvas.
3. Ajustar las propiedades en el panel derecho.
4. Ver el resultado en tiempo real.
5. Usar **SHOW** para mostrarlo a pantalla completa.
6. Usar **Compartir imagen** para exportar el diseño.

## Funciones de productividad para una segunda fase

- Guardar proyectos con nombre, fecha y miniatura.
- Duplicar un proyecto para hacer variaciones.
- Biblioteca de presets: aeropuerto, concierto, cumpleaños, boda, bienvenida y negocios.
- Historial de cambios por proyecto.
- Atajos de teclado: `Cmd/Ctrl + Z`, `Cmd/Ctrl + Shift + Z`, `Cmd/Ctrl + S` y `Cmd/Ctrl + E`.
- Arrastrar y soltar imágenes al canvas.
- Reordenar capas arrastrándolas.
- Bloquear capas para evitar cambios accidentales.
- Guías de alineación y centrar objetos.
- Exportar lotes de imágenes para varios mensajes.

## Sincronización con móvil

La versión de escritorio puede funcionar como el lugar de creación y el móvil como la pantalla de presentación.

- Enviar un proyecto al teléfono con un código QR o enlace local.
- Abrir el mismo proyecto en la app móvil.
- Usar el teléfono como pantalla secundaria o control remoto.
- Mantener los proyectos locales por defecto; sincronización en nube sólo si el usuario la activa.

## Prioridad sugerida

1. Establecer el layout de escritorio de dos columnas para todos los modos.
2. Guardar y abrir proyectos locales.
3. Completar Handwriting: opacidad, ocultar/bloquear capas y reordenar.
4. Exportar PNG a tamaño elegido.
5. Añadir presets y duplicación de proyectos.
6. Conectar escritorio y móvil.

## Objetivo de experiencia

El usuario debe sentir que está trabajando en un estudio pequeño y claro: crea a la izquierda, ajusta a la derecha, cambia de modo abajo y comparte el resultado con un solo botón.
