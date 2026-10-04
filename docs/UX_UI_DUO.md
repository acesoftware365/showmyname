# ShowMyName: UX/UI en Duo

Fecha: 3 de octubre de 2026.
Referencia: `../WakeNow/UX_UI_APRENDIZAJES_Y_PLAN.md` (aprendizajes aplicados al recorrido de crear y mostrar un cartel).

## Cambios implementados

- Inicio: la vista previa conserva la prioridad y Mostrar es la acción principal. Editar texto es secundaria. En espacio amplio, vista previa y modos comparten una fila; en ventanas estrechas o con texto grande vuelven a una columna. El diseño depende del ancho útil, no del nombre del dispositivo.
- Editor: campo de texto visible inicialmente; Apariencia agrupa tamaño, colores, negrita, icono y alineación. La vista previa pasa al lado del formulario solo cuando hay espacio suficiente. En compacto, el texto aparece primero.
- Listo permanece fuera del contenido desplazable y por encima del teclado. Cerrar y Listo conservan los cambios, que se aplican en vivo; no se presentan como acciones de cancelar.
- El formulario conserva identidad, texto, selección y expansión al cambiar de distribución. No se abre el teclado automáticamente antes de tocar el campo.
- Los editores de texto, concierto, ColorWave y escritura se presentan en el navegador raíz y respetan zonas seguras; el anuncio queda detrás del modal.
- El modo seleccionado incluye un símbolo de confirmación y semántica de selección; el estado no depende solo del color. Se redujo el brillo de selección y de vista previa.
- El banner tiene espacio reservado durante la carga. En iOS usa el tamaño estándar 320 × 50, como el ajuste documentado de WakeNow para Duo. Se ocultan anuncios que excedan el espacio actual.
- Si el sistema informa una separación de pantalla, DisplayFeatureSubScreen mantiene la aplicación en una región. No se implementó contenido atravesando una bisagra.
- Nuevas etiquetas traducidas a los diez idiomas existentes. Se conservan las traducciones pendientes anteriores del proyecto.

## Verificación

- Suite de 11 pruebas aprobada: ocho combinaciones de tamaño/texto, dos recorridos de edición y la prueba existente del arnés.
- Edición probada con teclado simulado, cambio entre 386 × 650, 678 × 466 y 960 × 700, texto al 100 % y 200 %, conservación del cursor, cierre y reapertura.
- Las pruebas comprueban que el modal cubre el banner y que Listo queda por encima del teclado.
- Inicio y banner observados en iPhone Duo; cambios cargados en la sesión de desarrollo.
- Análisis estático sin errores ni advertencias; permanecen avisos informativos anteriores de APIs obsoletas y uso de contexto asíncrono.

## Límites y siguiente trabajo

La inspección visual del editor y sus interacciones en hardware físico iOS/Android siguen pendientes. Las pruebas de teclado y cambios de tamaño son pruebas de widgets, no validan todos los teclados nativos ni todas las posturas físicas. El cambio del banner iOS no migra la lógica de solicitudes obsoletas de banners Android. El aviso de Google Play Billing sigue siendo una tarea separada pendiente.

## Revisión aprobada: cartel con menú flotante

Esta revisión sustituye el editor grande de dos paneles descrito arriba.

- El cartel ocupa el área principal. Un selector compacto permite cambiar el modo; Apariencia abre un menú de 320 puntos en la esquina superior derecha.
- El menú contiene mensaje, tamaño con botones −/+, colores, negrita, icono y alineación. Cerrar, tocar fuera y Listo conservan los ajustes en vivo. El contenido puede desplazarse con teclado o texto grande.
- El menú no redistribuye ni oscurece la vista previa. Inicio conserva su geometría cuando aparece el teclado; el menú sí respeta el espacio del teclado.
- La vista previa utiliza DisplayScreen sin controles de salida, con el tamaño lógico de la ventana final, y después se reduce uniformemente. Así usa el mismo motor, límites tipográficos, márgenes y saltos de línea que el resultado. Los efectos animados comparten implementación; la fase temporal de dos instancias puede diferir.
- Se retiraron el límite de letra especial de la vista previa de Inicio y el cálculo independiente de sus colores animados. El resultado de texto respeta el mismo recorte de espacios que Mostrar.
- Suite actual: 13 pruebas aprobadas, incluidas dos comparaciones de tamaño lógico, estilo y dimensiones del texto entre vista previa y pantalla final, además de edición con teclado y cambios de tamaño.
