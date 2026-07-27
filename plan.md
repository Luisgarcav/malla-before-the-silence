# MALLA: BEFORE THE SILENCE

## Plan de diseño y desarrollo

Estado: prototipo web  
Versión del plan: 1.6  
Plataforma inicial: navegador web moderno  
Tecnología: SvelteKit + Odin/WASM + Nix  
Duración jugable objetivo: 40 a 60 minutos  
Duración dentro de la historia: 4 a 5 horas

---

## 1. Visión

### Pitch

`MALLA: BEFORE THE SILENCE` es un thriller de terror político cyberpunk jugado
desde una web que representa la terminal de una laptop de mantenimiento. La
interfaz viaja con Ellie: cada conexión exige alcanzar físicamente un nodo
distinto. Mientras una
insurrección ocupa las calles, una junta cívico-militar toma el poder y
convierte el núcleo de la red pública en una máquina de vigilancia y control.
Ellie debe atravesar la ciudad y reencontrarse con Tom, su pareja, antes del
cierre total.

Para avanzar, el jugador inspecciona infraestructura, recupera mensajes y
extrae expedientes técnicos. La laptop entrega capturas, registros, metadatos y
documentación del sistema, pero no formula el problema por el jugador. Éste debe
diagnosticar qué falta, decidir cómo obtenerlo y trabajar fuera del juego con
las herramientas reales que prefiera. La laptop sólo recibe una intervención
operativa mínima y verifica si es compatible con el sistema local.

### Promesa de la experiencia

- Una historia sencilla: dos personas intentan volver a verse.
- Un conflicto grande visto desde una escala íntima.
- Terror producido por el Estado, la incertidumbre y la infraestructura
  cotidiana convertida en un arma, no por monstruos ni fenómenos mentales.
- Hacking creíble, limitado por permisos, topología, tiempo y rastros.
- Incidentes técnicos basados en sistemas reales, con evidencia suficiente y
  una razón narrativa.
- Un final sobre llegar a la otra persona, no sobre salvar al mundo.

### Pilares

1. **La relación va primero.** Cada sistema y cada análisis debe acercar o
   separar a la pareja.
2. **La red es el escenario.** Transporte, energía, radio, fábricas y vigilancia
   forman un mismo organismo urbano.
3. **El horror es institucional.** Órdenes impersonales, listas, cierres,
   correlación de datos y silencios en la comunicación sustituyen al monstruo.
4. **Los algoritmos son acciones.** No habrá acertijos arbitrarios disfrazados
   de programación.
5. **Poco alcance, alta densidad.** Una noche, una ciudad sin nombre, dos
   personajes centrales y una sola meta.

---

## 2. Decisiones no negociables

- El juego se llama `MALLA: BEFORE THE SILENCE`.
- MALLA es tanto la infraestructura cívica como la interfaz que acompaña a
  Ellie por la ciudad.
- El subtítulo alude al cierre de comunicaciones y al tiempo emocional que le
  queda a la pareja para reencontrarse.
- Nunca se nombra la ciudad, el país, el continente ni una nacionalidad.
- No aparecen personajes históricos reales.
- La situación política es ficticia, aunque su funcionamiento se investiga a
  partir de golpes de Estado, dictaduras y cortes de comunicaciones reales.
- La pareja es el centro dramático; la insurrección es el contexto y el peligro.
- Ellie y Tom recorren rutas distintas. Cada acto debe mover o reubicar a ambos;
  ninguno funciona como operador estático ni voz anclada a una base.
- No hay combate, poderes, implantes mentales ni una conspiración sobrenatural.
- SvelteKit es el único frontend y Odin contiene la lógica autoritativa.
- Nix contiene compilador, herramientas, pruebas y empaquetado.
- La distribución es un sitio estático con `game.wasm`; no requiere backend.
- No hay datos, imágenes, audio ni configuración obtenidos desde servicios
  externos durante una partida. Todo el contenido viaja dentro del sitio.
- El juego jamás ejecuta código escrito por el jugador.
- Ningún sistema le pide a Ellie “resolver un reto”. Ella crea herramientas
  porque necesita reconstruir, comparar o enrutar datos para seguir avanzando.

### Qué significa “sitio estático”

El repositorio sí tendrá varios archivos fuente, pruebas, `flake.nix`,
`flake.lock` y documentación. El artefacto de distribución contiene HTML, CSS,
JavaScript y WebAssembly en `result/share/malla-before-the-silence-web/`. Puede
publicarse en cualquier hosting estático y no depende de servicios del juego.

El flake se valida inicialmente en `x86_64-linux`, pero el artefacto resultante
se ejecuta en navegadores modernos de escritorio y móvil.

---

## 3. Dirección narrativa

### Logline

En las horas de un golpe de Estado, una persona que ayudó a mantener una red
cívica cuyo núcleo fue secuestrado por la nueva junta usa accesos locales
residuales para cruzar una ciudad paralizada y reunirse con su pareja, que
intenta llegar desde el extremo opuesto.

### El mundo

La época es deliberadamente indeterminada. La tecnología combina terminales
industriales, radio analógica, enlaces de fibra, cámaras, transporte automático
y centros de cómputo austeros. Debe sentirse como un futuro que creció sobre
infraestructura vieja, reparada muchas veces.

La **MALLA** es una red distribuida creada para coordinar recursos civiles:
energía, hospitales, talleres, alimentos, transporte y comunicaciones de
emergencia. Conserva nodos locales y rutas de respaldo porque fue diseñada para
seguir operando durante desastres.

Una insurrección popular lleva semanas ocupando fábricas y calles. Durante
meses, una alianza militar y corporativa preparó el golpe con personal
infiltrado, credenciales instaladas de antemano y procedimientos de emergencia
manipulados. En la noche del juego toma la autoridad central de identidad, los
gateways troncales, el centro de operaciones y las emisoras principales. Desde
ahí impone toque de queda y reutiliza las partes centrales de la MALLA para
cerrar rutas, correlacionar identidades, desplegar drones y emitir órdenes de
detención.

La toma no es total. Nodos locales, controladores industriales y rutas de
respaldo permanecen aislados, desactualizados o bajo operadores que todavía
resisten. Esa heterogeneidad explica por qué Ellie conserva oportunidades de
acceso y por qué la junta necesita correlacionar sus movimientos en lugar de
expulsarla instantáneamente de toda la red.

No se explicará qué partido gobernaba, qué bando “ganará” ni dónde ocurre. El
trasfondo sólo debe ser tan concreto como lo que Ellie y Tom necesitan para
sobrevivir esa noche.

### Personajes

**Ellie, protagonista**

- Especialista de mantenimiento de la MALLA.
- Lleva una laptop industrial, adaptadores de campo y una copia parcial de la
  topología. La laptop es su herramienta, no una base de operaciones remota.
- Conoce protocolos, dependencias y fallos heredados, pero no tiene acceso
  absoluto.
- Abandona el anexo durante el prólogo y cambia de ubicación durante todos los
  actos.
- Al comenzar todavía cree que una infraestructura bien diseñada puede ser
  neutral. La noche demuestra que toda red también expresa quién tiene las
  llaves.
- El jugador toma decisiones operativas, no define su personalidad mediante un
  árbol moral.

**Tom, pareja**

- Técnico de una emisora comunitaria conectada a la red de emergencia.
- Lleva un transceptor, una terminal portátil y herramientas para intervenir
  repetidores y gabinetes en persona.
- Conoce radios, repetidores y rutas físicas que Ellie no conoce.
- No espera ser rescatado: se mueve, repara enlaces, abre rutas y modifica datos
  desde el otro lado.
- Sus mensajes contienen información útil y decisiones propias. A veces Ellie
  sólo puede avanzar porque Tom actuó primero.

Los nombres definitivos para el MVP son Ellie y Tom.

### Regla de movilidad

Ningún personaje central permanece como una voz fija en una sala:

- Ellie se desplaza físicamente entre nodos y abre su laptop sólo cuando
  encuentra cobertura, un puerto de mantenimiento o una conexión cableada.
- Tom recorre una ruta diferente y accede con su terminal portátil a emisoras,
  enlaces de azotea y una subestación.
- Cada acto actualiza la posición de ambos. El mapa distingue posición
  confirmada, posición estimada y señal perdida.
- Las sesiones no sobreviven al movimiento: Ellie debe desconectarse, guardar
  sólo los datos permitidos y volver a autenticar en el siguiente sitio.
- Moverse no es una elipsis gratuita. Consume ventana de cierre, modifica
  exposición y produce escenas breves en calles, túneles o interiores.
- La batería de la laptop alcanza para la ventana narrativa del MVP. No se
  añade una barra de batería artificial, pero algunos nodos pueden impedir una
  conexión prolongada por falta de energía.

El jugador controla directamente a Ellie. La ruta de Tom no es controlable,
pero tampoco es decorativa: sus movimientos alteran accesos, capacidades y
mensajes que Ellie encuentra después.

### Relación

Ellie y Tom discutieron esa mañana. Tom quería abandonar la ciudad antes de que
la situación empeorara; Ellie insistió en terminar un turno de mantenimiento
porque la red todavía mantenía servicios esenciales. Habían quedado de verse
después del turno en un pequeño repetidor analógico fuera de la MALLA moderna,
un lugar que ambas personas conocen.

La historia no necesita infidelidad, identidad secreta, enfermedad terminal ni
un gran giro. Su tensión emocional nace de una pregunta ordinaria: cuando todo
lo demás exige su atención, ¿seguirán eligiendo avanzar hacia la otra persona?

### Referencia musical

La referencia emocional principal es **“Hush” de Muse con Ellie Goulding**. Se
toma su cualidad de dueto, el contraste entre intimidad y escala, y la sensación
de dos voces que todavía pueden responderse. No se adaptan la letra, personajes,
frases, melodía ni argumento.

Interpol puede servir como referencia secundaria para la alienación urbana y
la dificultad de comunicarse, pero no como base del relato. La idea funciona
mejor con “Hush” porque el juego también está construido como un intercambio:
mensaje de Ellie, respuesta de Tom, silencio y nueva respuesta.

### Arco emocional

1. **Interrupción.** Una conversación cotidiana queda cortada por la toma de la
   red.
2. **Confirmación.** Ellie recupera un paquete dañado y sabe que Tom sigue en
   movimiento.
3. **Distancia.** El mapa muestra que ambas personas están separadas por una
   ciudad que se cierra.
4. **Reciprocidad.** Tom cambia físicamente la red y permite que Ellie continúe.
5. **Silencio.** La señal desaparece en el último tramo. El jugador no sabe si
   el plan sigue vigente.
6. **Encuentro.** Las dos rutas convergen en el repetidor. El triunfo es físico,
   pequeño y momentáneo; el régimen continúa afuera.

### Regla de escritura

Cada fragmento narrativo debe cumplir al menos una función:

- revelar algo de la relación;
- cambiar la comprensión de la ciudad;
- aportar información operativa;
- mostrar una consecuencia de las acciones del jugador.

No habrá archivos coleccionables de exposición ni monólogos que expliquen la
historia política completa.

### Regla de presentación

- Cada escena empieza con hora y lugar; después separa diálogo, acción y cambio
  de situación mediante etiquetas breves como `ANTES`, `AHORA`, `CONFIRMADO` o
  `SIN RESPUESTA`.
- La relación se presenta en intercambios concretos y recuerdos vinculados a un
  objeto presente, no mediante una biografía. Ellie reconoce el transmisor de
  Tom porque ambos lo repararon; esa línea vale más que un archivo de lore.
- Los hitos técnicos importantes tienen una consecuencia narrativa paralela:
  detectar el controlador, abrir el expediente, leer el diagnóstico, dejar un
  rastro y recuperar el mensaje cambian la escena de la derecha.
- Consultar una fuente, ayuda o pista nunca reemplaza la última escena. La
  historia permanece visible mientras el jugador trabaja.
- Los sistemas muestran el golpe mediante cerraduras, autoridades cambiadas,
  colas de auditoría, altavoces y canales vacíos antes de explicarlo en prosa.
- La interfaz distingue hechos confirmados de inferencias y de silencios. No
  convierte una señal incompleta en conocimiento omnisciente.
- La narrativa no sólo coexiste con el trabajo técnico: lo interrumpe. Los
  mensajes de Tom y los cambios de red pueden llegar de forma asíncrona
  mientras el jugador consulta evidencia, y aparecen en el panel narrativo en
  el momento en que ocurren, con una marca visible de que hay una escena nueva.
  El ritmo de estos eventos se calibra para que ningún incidente transcurra
  completo sin al menos un acontecimiento narrativo intermedio.
- Releer la historia es gratuito. El comando `log` reimprime las últimas
  escenas completas sin coste de tiempo ni exposición, para que quien vuelve
  de trabajar fuera del juego recupere el contexto sin penalización.

---

## 4. Estructura de la partida

### Prólogo: ANTES DEL SILENCIO

Duración: 3 a 5 minutos.

- Antes de abrir la terminal, cinco láminas breves presentan la función civil de
  la MALLA, la diferencia entre la insurrección y el golpe, las rutas de Ellie y
  Tom, su promesa de reunirse en REP06 y los límites del acceso local.
- Ellie realiza una comprobación rutinaria en un anexo de operaciones.
- Una transmisión breve con Tom establece la discusión y el punto de encuentro.
- Los canales públicos cambian de programación.
- Aparece una orden de “estabilización”, seguida por cierres y pérdida de
  enlaces.
- La autoridad central activa credenciales preparadas antes del golpe. Ellie
  conserva un certificado regional de mantenimiento, su llave física y una
  copia parcial de la topología. Ninguno concede acceso global.
- Ellie desconecta su laptop, guarda una copia parcial de la topología y sale
  por un corredor de servicio. El anexo queda bloqueado y no funciona como base.
- Tom desmonta el transmisor portátil de la emisora y abandona el edificio por
  otra ruta.

### Acto I: LA TOMA

Duración: 15 a 25 minutos.

- La junta toma la identidad central, los gateways troncales y el centro de
  operaciones, pero no logra reconfigurar todos los nodos locales.
- Ellie cruza del Anexo de Operaciones al Taller Automatizado y conecta su
  laptop a un puerto industrial heredado.
- Ellie descubre que el sistema cívico ahora produce rutas de patrulla y listas
  de bloqueo.
- Llega un mensaje incompleto de Tom.
- Ellie reconoce el número de serie del transmisor que ambos repararon, abre el
  expediente y contrasta captura, protocolo, diagnóstico e integridad.
- El jugador determina fuera del juego cómo reconstruir el registro. El canal
  de retorno permanece sin portadora, de modo que Tom no sabe si Ellie recibió
  el mensaje.
- El mensaje confirma que Tom dejó la emisora, alcanzó un Enlace de Azotea y va
  hacia el repetidor.

### Acto II: LA CIUDAD SE CIERRA

Duración: 18 a 30 minutos.

- Ellie abandona el taller, atraviesa una zona de cierres y accede desde su
  laptop a un nodo local de transporte en el Intercambiador.
- Los caminos cambian por barricadas, retenes, apagones y ventanas de paso.
- Ellie reúne reportes con hora y confianza distintas, construye un grafo
  temporal y escribe una herramienta para comparar rutas.
- El jugador cruza tres espacios funcionales y ve cómo servicios civiles se
  transforman en puntos de control.
- Tom desciende del enlace, reporta sus propios desvíos y avanza hacia la
  Subestación. Su última posición confirmada cambia en el mapa.

### Acto III: INFRAESTRUCTURA HOSTIL

Duración: 18 a 25 minutos.

- El repetidor necesita alimentación física y una ruta de datos para abrir un
  canal.
- Ellie se desplaza hasta un gabinete del Corredor de Servicio y establece una
  nueva sesión desde la laptop; ya no conserva acceso al Intercambiador.
- La junta ya ocupa la mayor parte del backbone. Las capacidades disponibles
  representan únicamente canales de datos y ya descuentan tráfico reservado
  para servicios esenciales.
- Tom llega a una subestación secundaria, restaura físicamente la alimentación
  del repetidor y habilita su interfaz de red.
- Ellie recibe la nueva topología y escribe una herramienta de flujo de costo
  mínimo para reservar rutas primaria y de contingencia hasta el repetidor.
- Aplicar la distribución activa el canal de datos, pero también permite a la
  junta correlacionar el patrón de acceso de Ellie.

### Acto IV: ÚLTIMA PORTADORA

Duración: 15 a 22 minutos.

- La interfaz pierde color y reduce su información a medida que cae la señal.
- El canal de datos abierto en el Acto III pierde la sincronía: la red muere
  por tramos y el enlace final al Repetidor 06 no engancha la portadora.
- Tom deja de responder antes de confirmar su llegada. Lo que sí llega es un
  beacon de baja potencia que repite la última trama de sincronía que Tom dejó
  grabada en el repetidor: no es una respuesta, es una grabación agotándose.
- Incidente 4 (ÚLTIMA PORTADORA): las copias de la trama llegan cada vez más
  corrompidas. Ellie las reconstruye ponderando cada eco por su calidad de
  señal, extrae canal, desfase e identificador de repetición, y aplica `tune`. La autoridad central de
  integridad ya no existe: la única comprobación posible es la que la trama
  lleva dentro.
- Aplicar el `tune` correcto engancha la portadora, pero nadie responde al
  otro lado. El canal queda abierto hacia el silencio.

### Acto V: HUSH

Duración: 5 a 8 minutos, sin retos.

- Este tramo queda deliberadamente libre de trabajo técnico. Es el pago
  emocional del acto y no se interrumpe con expedientes ni comandos nuevos.
- Ellie cierra la sesión del gabinete y recorre a pie el último tramo hasta el
  Repetidor 06, en escenas breves con hora y lugar: calles vaciadas, altavoces,
  el transmisor de Tom sonando solo.
- La MALLA emite una última orden de captura y después queda fuera de alcance.
  La interfaz termina de perder el color.
- Tom aparece físicamente. El último intercambio debe ser breve y humano, no un
  discurso político.

### Finales

**Final principal: ENCUENTRO**

Ellie y Tom se reúnen. No detuvieron el golpe ni liberaron la ciudad; conservaron
una promesa y ahora deben decidir cómo sobrevivir al amanecer. Éste es el cierre
canónico y el objetivo principal de la partida.

**Estados de fracaso**

- La ventana de cierre llega a cero.
- La exposición alcanza el estado de interceptación.
- Ellie abandona explícitamente la partida.

El fracaso evita violencia gráfica. Una conexión cortada, una terminal
confiscada o una transmisión que ya no recibe respuesta bastan. Después del
fracaso se ofrece reiniciar el acto con la misma semilla.

---

## 5. Jugabilidad

### Bucle principal

1. Recibir un mensaje o cambio de estado mientras Ellie está en movimiento.
2. Inspeccionar el espacio físico y las rutas disponibles.
3. Elegir el siguiente nodo y desplazarse.
4. Abrir la laptop y detectar interfaces locales.
5. Conectarse usando un puerto y permiso concretos.
6. Abrir un expediente y contrastar sus capturas, registros y documentación.
7. Diagnosticar el incidente y usar cualquier herramienta externa adecuada.
8. Introducir sólo la intervención mínima que aceptaría el sistema real.
9. Validar, actualizar la red y mostrar el avance de Tom.
10. Desconectarse antes de continuar el recorrido.

### Tiempo

El MVP no usa un cronómetro de pared. Penalizar la velocidad con la que alguien
programa perjudicaría accesibilidad, reflexión y depuración.

Los 40 a 60 minutos describen la duración de una partida. Dentro de la ficción,
el recorrido comienza antes del cierre nocturno y termina entre cuatro y cinco
horas después. Los desplazamientos representan trayectos de varios minutos,
esperas, escondites y desvíos, aunque el texto los condense.

El tiempo es una **ventana de cierre** medida en turnos narrativos:

- moverse consume unidades conocidas;
- usar un sistema privilegiado consume unidades conocidas;
- esperar consume una unidad;
- errores de formato no consumen nada;
- una configuración que viola restricciones es rechazada, deja un registro y
  consume una unidad;
- una solución fuera de la tolerancia robusta o del óptimo declarado se
  rechaza; cada expediente publica su criterio.

Todos los costes se muestran antes de confirmar una acción. No hay muerte
aleatoria ni temporizadores ocultos.

### Exposición

La exposición representa cuánta evidencia correlacionable deja Ellie:

1. `ANÓNIMO`
2. `CORRELACIONADO`
3. `LOCALIZADO`
4. `INTERCEPTACIÓN`

Sube al usar nodos vigilados, aplicar configuraciones rechazadas o atravesar
rutas con sensores. Baja sólo en puntos específicos que tengan una razón
física, como un enlace analógico o un terminal fuera de línea. El sistema
siempre explica qué acción cambió la exposición.

### Mapa

El mapa no usa topónimos y muestra dos recorridos simultáneos.

Ruta controlada de Ellie:

`Anexo de Operaciones -> Taller Automatizado -> Intercambiador -> Corredor de Servicio -> Repetidor 06`

Ruta autónoma de Tom:

`Emisora Comunitaria -> Enlace de Azotea -> Subestación -> Repetidor 06`

Son ocho nodos únicos porque ambos comparten el destino. La interfaz sólo
muestra la última ubicación verificable de Tom y la hora del reporte; no ofrece
conocimiento omnisciente. Los cierres, retenes y rutas también muestran fuente,
hora y confianza: `CONFIRMADO`, `PROBABLE` o `NO_VERIFICADO`. `move` representa
un desplazamiento físico, dispara una escena y consume tiempo. La ciudad
completa no es explorable y no es posible volver al anexo como refugio.

### Comandos

`help`  
`status`  
`scan`  
`map`  
`move <nodo>`  
`connect <sistema>`  
`messages`  
`log`  
`inspect <registro>`  
`evidence <fuente>`  
`evidence <fuente> --raw`  
`repair <registro> <dato>`  
`tune <sistema> <canal> <desfase> <id_repetición> <crc16_hex>`  
`hint [1-5]`  
`disconnect`  
`wait`  
`quit`

No existe un comando genérico `hack` que resuelva cualquier situación. Cada
conexión exige que la ubicación, el puerto, el permiso y el sistema sean
compatibles. `inspect` abre un expediente, `evidence` consulta una fuente sin
interpretarla y `repair` realiza una escritura concreta que queda registrada.
`evidence <fuente> --raw` imprime el bloque de datos limpio, sin marcos, color
ni reajuste de líneas, pensado para copiarse directamente a una herramienta
externa; los datos crudos nunca dependen del ancho del panel. `log` reimprime
las últimas escenas narrativas completas y no consume tiempo ni exposición.
`tune` escribe parámetros de sincronía en un receptor local; cada intento de
enganche queda registrado y un barrido fallido es visible para la red.
Ninguno decide qué herramienta necesita el jugador ni transforma evidencia en
una solución. `move` no funciona con una sesión abierta; primero se debe usar
`disconnect`.

El parser acepta mayúsculas o minúsculas, espacios adicionales y abreviaturas
no ambiguas. Ante un error propone un comando válido sin modificar el estado.

### Expedientes técnicos

Cada incidente entrega suficiente información para investigarlo sin depender
de conocimiento oculto ni de buscar la solución en internet. La información no
se organiza como tutorial del algoritmo, sino como fuentes que existirían por
razones operativas:

1. contexto del incidente: sistema, hora, origen, síntoma y acción bloqueada;
2. captura o conjunto de datos en un formato copiable y documentado;
3. diagnóstico cronológico del equipo que produjo o recibió esos datos;
4. extracto de la especificación relevante, con versión y semántica de campos;
5. contrato de integridad y condición que el sistema verificará al escribir.

Las fuentes pueden superponerse deliberadamente. El jugador debe decidir qué es
señal y qué es contexto, comparar identificadores y formular su propio método.
No habrá pseudocódigo, ejemplo resuelto, editor, REPL, calculadora ni selección
de lenguaje dentro del juego. El jugador puede usar fuera del juego shell,
Python, una hoja de cálculo, una calculadora, papel o una herramienta propia.

La sintaxis de la intervención final siempre se muestra con claridad. Descubrir
un comando inventado no forma parte del reto; diagnosticar y producir el dato
correcto sí.

### Sistema de pistas

Cada incidente ofrece cinco niveles acumulativos y opcionales:

1. identifica qué observación conviene priorizar;
2. señala qué fuente relaciona los datos relevantes;
3. explica el principio técnico sin escribir un programa;
4. revela un resultado parcial comprobable;
5. entrega una solución de desbloqueo y la acción final exacta.

`hint` muestra el índice y `hint <1-5>` abre el nivel elegido. Las pistas no se
consumen, no modifican tiempo ni exposición y pueden releerse. Son una capa de
accesibilidad externa a la ficción: la presión narrativa sólo responde a
acciones dentro del mundo, nunca a que una persona necesite más contexto.

---

## 6. Incidentes técnicos

### Reglas comunes

- Los datos son deterministas a partir de `?seed=<u64>`.
- Toda semilla publicada debe producir una instancia soluble y acotada.
- La ficción presenta un sistema detenido, sus fuentes y una necesidad humana.
  La interfaz puede declarar que el nivel es experto y que conviene programar,
  pero no prescribe lenguaje, biblioteca ni implementación.
- Cada expediente identifica procedencia, hora, versión, unidades, codificación,
  valores ausentes y alcance de cualquier comprobación de integridad.
- La interfaz nunca propone lenguaje, biblioteca, comando externo o estructura
  de programa. El jugador formula y ejecuta su método por separado.
- La intervención final es corta porque representa una escritura o decisión
  operativa, no porque el juego finja ser un editor.
- El validador comprueba propiedades, no una cadena rígida, cuando existen
  varias soluciones correctas.
- Los retos de nivel experto pueden exigir una solución robusta o un óptimo
  global. La política declara la tolerancia operativa y evita fingir precisión
  cuando los datos de entrada son inciertos.
- La implementación incluye un solver de referencia sólo para pruebas y para
  generar instancias. Nunca se expone durante una partida normal.
- El motor trata la respuesta como datos. No evalúa expresiones, no abre
  procesos y no carga bibliotecas del usuario.
- Las herramientas externas no necesitan acceso a internet ni un producto
  concreto; toda la evidencia imprescindible vive en el expediente.

### Incidente 1: REGISTRO EMR-06

**Fundamento real:** recuperación de dos pérdidas conocidas mediante paridad
P/Q, equivalente al esquema de doble erasure de RAID-6: XOR más un síndrome
Reed-Solomon sobre GF(2⁸).

**Fuentes del expediente**

- metadatos de recepción con identificador, hora, origen y versión de protocolo;
- doce slots de datos binarios de 16 octetos, representados en hexadecimal, y
  estado de recepción de cada uno;
- slots de recuperación P y Q recibidos por separado;
- log que localiza ambas pérdidas después de sus encabezados; la semilla
  determina los dos índices en cada instancia;
- extracto MESH-ER/2 que define la relación entre datos y recuperación;
- perfil CRC-32/ISO-HDLC, alcance binario y valor esperado autenticado.

**Diagnóstico esperado**

Determinar que existen dos erasures recuperables y resolver, para cada una de
las 16 posiciones, el sistema `A XOR B = p'` y
`α^a·A XOR α^b·B = q'` en GF(2⁸), con polinomio primitivo 0x11D. Después se
comprueba que el registro completo satisface CRC-32. Un script o una
formulación algebraica es la vía prevista; el tanteo manual no es viable.

**Intervención**

`repair emr-06 <64 dígitos hexadecimales>`

La respuesta concatena primero el bloque perdido de índice menor y después el
de índice mayor.

No se pide volver a introducir el checksum esperado ni declarar valores que el
controlador puede derivar por sí mismo.

**Validación**

- longitud y alfabeto hexadecimal correctos;
- síndrome P correcto por posición;
- síndrome Q correcto en GF(2⁸) por posición;
- checksum del mensaje completo correcto.

**Función narrativa**

Ellie observa que faltan exactamente dos fragmentos, exporta la captura con
`evidence capture`, contrasta la especificación y el diagnóstico, y repara sólo
los slots perdidos. Así recupera el primer mensaje de Tom. No se presenta como
“romper cifrado”; aprovecha redundancia de un protocolo de emergencia que ya
conoce.

**Dificultad objetivo:** 12 a 20 minutos, nivel experto y código recomendado.

### Incidente 2: CIUDAD CERRADA

**Fundamento real:** enrutamiento sobre un grafo con pesos no negativos y
ventanas de disponibilidad e incertidumbre acotada.

**Fuentes del expediente**

- exportación de tramos dirigidos con origen, destino y duración estimada;
- boletín de cierres con inicio, fin, emisor y hora de publicación;
- registro de sensores con nivel de rastro y última observación;
- reportes humanos con fuente y confianza `CONFIRMADO`, `PROBABLE` o
  `NO_VERIFICADO`;
- última posición verificable de Tom y hora de recepción;
- extracto de la política de despacho que convierte confianza y antigüedad en
  una demora máxima y define el criterio minimax.

Cada tramo tiene duración `[minutos, minutos + demora_máxima]`, donde:

`demora_máxima = demora_confianza + floor(antigüedad / 10)`

La demora base es 0 para `CONFIRMADO`, 3 para `PROBABLE` y 8 para
`NO_VERIFICADO`, más un punto por cada diez minutos completos desde el último
reporte.

Se propagan llegada temprana y tardía. Una arista es robusta sólo si todo el
intervalo posible de salida queda fuera de su cierre. El costo es
`llegada_tardía + 4 * rastro_total`; se acepta cualquier ruta dentro de tres
puntos del mínimo minimax.

**Diagnóstico esperado**

Cruzar fuentes que pueden haber envejecido a horas distintas, descartar tramos
que podrían estar cerrados en alguna realización del intervalo y demostrar una
ruta dentro de la banda robusta entre 18 aristas. El jugador puede enumerar
caminos simples con código o resolver un problema de optimización minimax.

**Intervención**

`route ellie <tramo-1>><tramo-2>><tramo-n>`

El sistema deriva llegada, rastro, incertidumbre y coste. No obliga al jugador a
copiar de nuevo cuatro totales sólo para demostrar que los calculó.

**Validación**

- todas las aristas existen y son robustamente disponibles;
- se propagan correctamente las cotas temprana y tardía;
- el costo queda dentro de `minimax + 3`;
- una ruta insegura o fuera de margen se rechaza, consume ventana y aumenta
  exposición.

**Función narrativa**

Convierte reportes incompletos en una recomendación, no en conocimiento perfecto
de la calle. Después de aplicar la ruta, un reporte puede cambiar y obligar a un
desvío local breve; eso no vuelve incorrecto el cálculo para la información que
Ellie tenía. El sistema abstrae horarios, sensores y reportes locales sin
pretender simular una ciudad completa.

**Dificultad objetivo:** 15 a 25 minutos, nivel experto.

### Incidente 3: CAPACIDAD RESIDUAL

**Fundamento real:** reserva de flujo tolerante a fallos con costos enteros y
protección N-1. Se planifican un camino primario y otro de contingencia sobre
conjuntos disjuntos de enlaces.

**Fuentes del expediente**

- inventario de interfaces dirigido con gateway fuente y repetidor destino;
- telemetría fechada de capacidad física y tráfico observado;
- reservas civiles, headroom operativo y costo por unidad de cada enlace;
- log de la reparación física que Tom realiza en el repetidor;
- demanda mínima del canal y reglas del controlador para aplicar una asignación.

Las capacidades planificables descuentan tráfico civil y headroom. Este
incidente no modela electricidad ni modifica cargas de la red eléctrica. La
topología fuerza a transferir excedente de A o C hacia B o D mediante enlaces
cruzados. Cada uno de los dos planes debe sostener la demanda completa y no
pueden compartir ninguna arista, por lo que el fallo de un enlace conserva un
plan operativo.

**Diagnóstico esperado**

Construir dos flujos conservados y disjuntos, comprobar la demanda de cada uno
y minimizar `Σ(cantidad × costo_unitario)` sobre ambas reservas.

**Intervención**

`allocate rep-06 P:S-A=4,A-B=2,B-T=4,...;B:S-C=4,C-D=2,D-T=4,...`

Sólo se escriben asignaciones positivas. El controlador deriva demanda y costo.

**Validación**

- capacidad planificable respetada y headroom intacto;
- conservación independiente de P y B en nodos intermedios;
- ausencia de enlaces compartidos entre planes;
- demanda completa en cada plan;
- costo total igual al mínimo global; un par sobrevivible pero más caro se
  rechaza y deja rastro.

**Función narrativa**

Tom restaura en persona la alimentación del repetidor y enciende su interfaz;
esa acción agrega un enlace al grafo. Ellie sólo calcula y aplica la
reserva de tráfico de datos y contingencia. La separación deja claro que una
red eléctrica no funciona como este modelo de comunicaciones.

**Dificultad objetivo:** 15 a 20 minutos, nivel experto.

### Incidente 4: ÚLTIMA PORTADORA

**Fundamento real:** repetición como corrección de errores y combinación por
diversidad con decisión suave: cada bit observado aporta una razón de
verosimilitud según su probabilidad de error. La comprobación local usa
CRC-16/CCITT-FALSE, no una votación de bytes ni una paridad longitudinal.

**Situación**

El canal de datos del Acto III está abierto, pero el enlace final no engancha:
el repetidor cambió de canal y desfase cuando Tom restauró la alimentación. Tom
ya no responde. Antes de callar dejó el beacon del repetidor repitiendo su
última trama de sincronía; cada repetición llega más corrompida porque la
batería del beacon muere. La autoridad central de integridad —la que firmaba
los checksums del Incidente 1— es parte del núcleo tomado y ya no existe para
Ellie.

**Fuentes del expediente**

- contexto del incidente: receptor en modo degradado, portadora sin enganche,
  verificación central de integridad inalcanzable;
- captura: nueve copias de la trama BCN-R6 (16 octetos en hexadecimal), cada
  una con hora, RSSI, probabilidad de error por bit y peso LLR; las copias
  tardías llegan con nivel decreciente;
- diagnóstico del receptor: calibración BER y
  `ln((1-p)/p) × 100` por banda de señal;
- extracto de la especificación BCN-R6: estructura de la trama (sincronía,
  canal, desfase de reloj, identificador del transmisor, contador de
  repetición y CRC-16), la regla de que el emisor repite la trama idéntica y
  los parámetros exactos del checksum;
- condición de aplicación: rangos físicos que el receptor acepta para canal,
  desfase e identificador, y la advertencia de que cada intento de enganche
  queda registrado.

**Diagnóstico esperado**

Reconstruir la trama bit a bit. Por posición se suma `+LLR` para un 1 observado
y `-LLR` para un 0; el signo decide el bit y el valor absoluto debe alcanzar el
margen 100. La mayoría simple falla por diseño en campos críticos. Después se
verifica CRC-16/CCITT-FALSE sobre los octetos 0..13 contra 14..15 y se extraen
canal, desfase e identificador. La matriz de nueve ecos por 128 bits está
pensada para un programa o una hoja de cálculo.

**Intervención**

`tune rep-06 <canal> <desfase> <id_repetición> <crc16_hex>`

No se pide reescribir la trama completa: el CRC recuperado obliga a reconstruir
y comprobar la misma trama que contiene los parámetros de sincronía.

**Validación**

- canal, desfase e identificador dentro de los rangos físicos y CRC con cuatro
  dígitos hexadecimales;
  fuera de rango es error de formato y no consume nada;
- valores que no coinciden con la trama real: el receptor barre sin enganchar,
  el intento queda registrado, consume una unidad de ventana y aumenta la
  exposición;
- valores correctos: la portadora engancha; el juego no ofrece ninguna
  confirmación de Tom, sólo el canal abierto.

**Generación**

- la semilla fija la trama verdadera, los niveles de señal y el patrón de
  corrupción;
- nueve copias, número impar, con niveles decrecientes;
- en al menos tres octetos la mayoría de bits sin ponderar produce un valor
  incorrecto; la decisión LLR produce siempre la trama verdadera;
- todos los bits alcanzan el margen publicado y la trama satisface CRC-16;
  toda instancia publicada es soluble y acotada.

**Función narrativa**

El último trabajo técnico de la noche es literalmente escuchar muchas veces lo
que Tom dejó repitiéndose y decidir cuánto vale cada eco. El Incidente 1 abrió
el juego recuperando la voz de Tom con una red que todavía garantizaba: había
P/Q, había checksum autenticado, había confirmación. ÚLTIMA PORTADORA cierra el
círculo sin autoridad central: sólo repetición, calibración local, CRC y el
criterio de Ellie. Aplicar el `tune` correcto abre un canal hacia el silencio —la
reconstrucción funciona, y aun así nadie contesta—, lo que deja el peso del
cierre en el Acto V, donde ya no hay nada que resolver.

**Dificultad objetivo:** 12 a 18 minutos, nivel experto y código recomendado.

### Lo que se elimina del concepto anterior

- invertir cadenas sin contexto;
- sumar números elegidos arbitrariamente;
- “voltear binario” como cerradura;
- acertijos cuya única relación con el mundo sea la palabra hack;
- interfaces que ordenan “resolver Dijkstra” o muestran una puntuación;
- manuales con pseudocódigo y ejemplos resueltos dentro del juego;
- formularios que piden repetir checksums o totales que el sistema ya conoce;
- consolas ficticias que eligen o ejecutan la herramienta del jugador;
- respuestas codificadas para una sola instancia;
- ejecución de scripts del jugador;
- presión basada en tiempo real.

---

## 7. Realismo del hacking y del conflicto

### Modelo de acceso

- Ellie inicia con un certificado regional limitado por rol y caducidad. Para
  usarlo necesita una llave física registrada a su laptop.
- El certificado y la laptop no dan alcance remoto global. Ellie sólo ve
  interfaces conectadas al nodo físico actual o dentro de su cobertura
  inmediata.
- La credencial sólo funciona en controladores heredados de su región que aún
  confían en la antigua autoridad y reconocen la llave física.
- Los gateways centrales y los nodos ya reconfigurados por la junta rechazan la
  credencial.
- Cambiar de sitio termina la sesión anterior, cambia la dirección de red y
  genera un nuevo patrón de logs.
- Un acceso remoto no elimina una barrera física: sólo cambia señales, rutas o
  disponibilidad de infraestructura.
- Cada operación privilegiada crea logs. La amenaza surge de correlacionarlos,
  no de una barra mágica de “detección”.
- Tom debe realizar acciones físicas que Ellie no puede resolver desde una
  terminal.

### Modelo político

- Una insurrección popular y un golpe de Estado son hechos distintos. El golpe
  aprovecha el caos, pero no se llamará “revolución militar”.
- El golpe fue preparado con antelación y apoyo interno. La junta captura
  identidad, gateways y mando central, no cada dispositivo de la ciudad.
- La primera prioridad de la junta es controlar comunicaciones, movilidad,
  medios y centros productivos.
- La red fue construida con un fin civil. Su apropiación muestra que una
  arquitectura técnica no garantiza quién ejercerá el poder.
- Los comunicados oficiales usan lenguaje administrativo, no caricaturas
  malvadas.
- La violencia permanece presente en sirenas, transmisiones, cierres y
  desaparición de señales, sin convertir tortura o ejecuciones en espectáculo.

### Límites éticos

- No usar nombres, testimonios, fotografías, consignas ni centros de detención
  de víctimas reales.
- No recrear una ciudad o dictador reconocible con otro nombre.
- No puntuar muertes, coleccionar atrocidades ni usar tortura como mecánica.
- No equiparar todos los actores políticos para evitar tomar postura sobre la
  represión estatal.
- Una revisión de sensibilidad histórica debe ocurrir antes de congelar el
  guion.

---

## 8. Presentación web

### Objetivo visual

La web representa la pantalla de la laptop industrial que Ellie abre y cierra
mientras atraviesa la ciudad. Su interfaz se degrada conforme la junta toma la
red:

- marfil y verde para infraestructura civil;
- rojo sólo para órdenes de la junta y peligro inmediato;
- cian para mensajes de Tom;
- pérdida progresiva de color en el último acto;
- diagramas SVG y CSS para topología, paquetes y mapa.

El MVP no depende de ilustraciones, audio ni recursos externos. Todos los
recursos visuales forman parte del sitio estático.

### Composición responsive

La historia conserva prioridad visual sin ocultar el trabajo técnico:

- barra persistente con ubicación, conexión, ventana y exposición;
- mapa de red con la posición confirmada o estimada de Ellie y Tom;
- feed narrativo separado de los mensajes operativos;
- expediente con fuentes copiables y descargables;
- controles contextuales y entrada de comandos;
- layout amplio por columnas y layout móvil apilado;
- drawers o diálogos para evidencia extensa en pantallas pequeñas.

La interfaz debe poder recorrerse con teclado, conservar foco visible y usar
HTML semántico. El color refuerza el estado, pero nunca es su único indicador.
Las animaciones respetan la preferencia de movimiento reducido y los datos
técnicos no se truncan por el tamaño del viewport.

### Parámetros de sesión

La semilla reproducible se selecciona con `?seed=<u64>`. Fallar reinicia el acto
actual con la misma semilla; un código de reanudación sin archivo de guardado
puede explorarse después del MVP.

---

## 9. Arquitectura web + Odin/WASM

### Estructura

`src/algorithms.odin`  
`src/game.odin`  
`src/command.odin`  
`src/operation.odin`  
`src/evidence.odin`  
`src/web.odin`  
`src/tests.odin`  
`web/src/lib/game/`  
`web/src/lib/components/`  
`web/src/routes/`

SvelteKit es el único frontend. Odin no renderiza pantallas ni accede a la
terminal: conserva el estado autoritativo, genera instancias y valida
soluciones. `src/web.odin` expone una frontera pequeña compilada a WebAssembly.

### Núcleo

- `Game_State`: acto, ubicación, conexión, ventana, exposición e incidente.
- `Event_Code`: resultado estructurado de una acción.
- `Operation_Instance`: datos generados, contexto y semilla.
- `Validation_Result`: formato inválido, imposible, insuficiente, viable u
  óptimo.
- snapshots serializados como valores simples para el frontend.

Flujo principal:

`evento UI -> comando -> WASM -> transición Odin -> snapshot -> Svelte`

La interfaz nunca decide si una solución es correcta. Svelte presenta y
recopila acciones; Odin aplica reglas y devuelve el nuevo estado. La semilla
entra explícitamente y no se consulta entropía global durante pruebas.

### Dependencias

- Odin usa únicamente su biblioteca `core`.
- SvelteKit, TypeScript y el adaptador estático contienen la presentación.
- El puente JavaScript implementa sólo los imports requeridos por el runtime
  WASM.
- No se añade motor, VM, intérprete, base de datos ni servicio obligatorio.
- El juego se distribuye como HTML, CSS, JavaScript y `game.wasm`.

---

## 10. Nix y artefacto reproducible

### Flake

El repositorio tendrá:

- `flake.nix` con un único input principal, `nixpkgs`;
- `flake.lock` versionado para fijar Nixpkgs y Odin;
- `packages.x86_64-linux.default`;
- `apps.x86_64-linux.default`;
- `devShells.x86_64-linux.default`;
- `checks.x86_64-linux`.

Comandos oficiales:

`nix develop`  
`nix build`  
`nix run .`  
`nix flake check`

No se documentará como requisito instalar Odin, LLVM o utilidades globalmente.

### Compilación de lanzamiento

La derivación instala las dependencias fijadas por `pnpm-lock.yaml`, ejecuta
`pnpm run validate` y copia la salida de `adapter-static` a
`$out/share/malla-before-the-silence-web`. El mismo build compila
`src/` como `game.wasm`; no existe un ejecutable ni un frontend nativo
adicional.

### Checks de empaquetado

`nix flake check` debe demostrar:

- todas las pruebas Odin pasan;
- el build WASM termina sin warnings;
- Svelte Check, TypeScript, ESLint y Prettier pasan;
- las pruebas unitarias y la integración contra el WASM real pasan;
- el sitio estático contiene `index.html`, assets y `game.wasm`;
- el paquete no contiene `node_modules` ni fuentes de desarrollo;
- la app predeterminada sirve el sitio desde un entorno limpio.

El sitio resultante no requiere backend. El servidor incluido por Nix sólo es
una utilidad local para servir los archivos con un origen HTTP válido.

---

## 11. Estrategia de pruebas

### Unitarias

- parser, abreviaturas y errores sin efectos;
- conexión y desconexión al entrar o salir de cada nodo;
- rutas físicas y actualización independiente de ambas posiciones;
- alcance regional del certificado, presencia de llave física y rechazo de
  nodos reconfigurados;
- costes de movimiento y acceso;
- transiciones de exposición;
- disparadores narrativos;
- recuperación RAID-6 P/Q en GF(2⁸) y checksum;
- ruta temporal robusta, propagación de intervalos y banda minimax;
- planes de flujo disjuntos, conservación, headroom y costo mínimo;
- independencia entre alimentación física y capacidad de comunicaciones;
- reconstrucción LLR por bit de BCN-R6, margen, CRC-16 y rangos de `tune`;
- validadores con soluciones alternativas;
- generación determinista por semilla;
- reinicio de acto.
- disponibilidad de todas las fuentes del expediente;
- cinco niveles de pistas releíbles que nunca modifican estado ni recursos.

### Propiedades

Para muchas semillas acotadas:

- el solver de referencia siempre produce una solución aceptada;
- mutaciones inválidas de ruta violan al menos una regla;
- las rutas que solapan un cierre en alguna realización se rechazan;
- las rutas dentro de `minimax + 3` se aceptan y las restantes dejan diagnóstico;
- ningún plan supera capacidad, consume headroom ni rompe conservación;
- un par bajo demanda es insuficiente y un par sobrevivible más caro es subóptimo;
- aplicar flujo de datos nunca modifica el estado de alimentación eléctrica;
- en toda instancia del Incidente 4 la mayoría simple falla en al menos tres
  octetos y la decisión LLR reproduce la trama verdadera;
- la trama verdadera del beacon siempre satisface CRC-16 y el margen mínimo;
- la dificultad permanece dentro de límites de tamaño;
- la partida siempre conserva al menos una ruta de éxito.

### Integración

- el puente JavaScript carga el WASM real y completa cada acto;
- cada acción publica un snapshot coherente con el estado Odin;
- las cuatro fuentes pueden copiarse y descargarse sin alterar sus bytes;
- `log` recupera las escenas recientes sin modificar tiempo ni exposición;
- navegación por teclado, foco, contraste y movimiento reducido;
- layout comprobado en viewports amplios, tablet y móvil;
- ejecución del sitio estático sin acceso al árbol fuente;
- respuesta HTTP correcta para HTML, JavaScript, CSS y `application/wasm`;
- build y pruebas reproducibles desde Nix.

### Playtests

Registrar manualmente:

- tiempo por acto y por incidente;
- fuentes consultadas, nivel máximo de pista y herramienta externa elegida;
- momento en que el jugador formula con sus palabras qué dato necesita producir;
- comandos fallidos;
- momento en que el jugador entiende que Tom también avanza;
- si el jugador nota las escenas asíncronas que llegan mientras trabaja y si
  usa `log` para recuperar contexto al volver de su herramienta externa;
- claridad de que la terminal pertenece a una laptop móvil y no a una sala fija;
- claridad del golpe de Estado sin exposición enciclopédica;
- fuerza emocional del silencio final y del reencuentro;
- si el expediente se percibe como investigación técnica o como ejercicio
  académico disfrazado.

Metas:

- 80 % de jugadores encuentra por sí mismo la captura y la especificación;
- 60 % completa el primer incidente sin abrir las pistas 4 o 5;
- ningún incidente supera 15 minutos de mediana;
- en el Incidente 4, la mayoría de los jugadores descubre por las fuentes que
  las copias no valen lo mismo, sin necesidad de las pistas 3 a 5;
- el Acto V, HUSH, se percibe como el momento más fuerte del juego, no
  como una cinemática después del trabajo;
- al menos 4 de 5 jugadores describen a Tom como agente activo;
- al menos 4 de 5 pueden reconstruir el recorrido físico de Ellie y Tom;
- al menos 4 de 5 entienden que la meta era reunirse, no derrotar al régimen.

---

## 12. Fases de desarrollo

### Fase 0: riesgo técnico

Entregables:

- `flake.nix` y `flake.lock`;
- “hello world” Odin/WASM construido sólo mediante Nix;
- sitio estático mínimo que carga el módulo;
- frontera tipada entre Svelte y Odin;
- esqueleto de `nix flake check`.

Criterio de salida:

`nix build` genera un sitio estático autónomo y las comprobaciones reproducibles
lo demuestran.

### Fase 1: prototipo de papel

Entregables:

- guion completo en formato de transcript;
- mapa doble de ocho nodos y posición de ambos personajes por acto;
- especificación exacta de los cuatro incidentes canónicos;
- expediente, fuentes, pistas y resultados esperados de cada incidente;
- tabla de cada acción de Tom y su efecto jugable;
- revisión histórica inicial.

Criterio de salida:

La partida puede recorrerse de principio a fin leyendo el transcript y
creando las cuatro herramientas fuera del juego.

### Fase 2: motor autoritativo

Entregables:

- parser;
- máquina de estados;
- mapa doble y movimiento físico;
- sesiones locales de conexión y desconexión;
- actualización independiente de las posiciones de Ellie y Tom;
- tiempo por turnos y exposición;
- mensajes y progresión por actos;
- reinicio determinista.

Criterio de salida:

Una prueba automatizada completa la historia directamente contra el motor.

### Fase 3: incidentes y validadores

Entregables:

- generadores acotados;
- cuatro solvers de referencia;
- cuatro validadores;
- expedientes con fuentes técnicas independientes;
- cinco pistas progresivas y gratuitas por incidente;
- pruebas unitarias y por semillas.

Criterio de salida:

Cada solución viable se acepta por propiedades y las configuraciones imposibles
se rechazan con mensajes útiles.

### Fase 4: integración narrativa

Entregables:

- texto final de Ellie y Tom;
- acciones paralelas visibles;
- consecuencias de tiempo y exposición;
- finales y reinicio de acto;
- pase completo de ritmo.

Criterio de salida:

La relación se entiende sin archivos de lore y cada incidente modifica la
situación de la pareja.

### Fase 5: presentación y accesibilidad

Entregables:

- componentes Svelte accesibles y tematizables;
- layout responsive amplio y móvil;
- evidencia copiable y descargable;
- `log` integrado con el feed narrativo;
- eventos narrativos asíncronos visibles durante el trabajo técnico;
- estados de carga y error del módulo WASM;
- revisión de teclado, foco, legibilidad y mensajes de error.

Criterio de salida:

La experiencia funciona en navegadores modernos de escritorio y móvil sin un
backend obligatorio.

### Fase 6: lanzamiento del MVP

Entregables:

- todos los checks de Nix;
- sitio estático optimizado con WASM;
- playtests de duración y dificultad;
- revisión de sensibilidad histórica;
- correcciones de contenido e interacción;
- versión `0.1.0`.

Criterio de salida:

Se cumple toda la definición de terminado.

---

## 13. Riesgos y mitigaciones

| Riesgo                                                  | Impacto                                   | Mitigación                                                                                                                                           |
| ------------------------------------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Los incidentes parecen tarea escolar                    | Rompe tensión                             | Fuentes con procedencia y propósito operativo; la ficción nunca anuncia un algoritmo ni otorga puntos                                                |
| El jugador tarda demasiado construyendo una herramienta | Ritmo muerto                              | Tiempo por turnos, instancias pequeñas, formatos copiables y libertad de herramienta                                                                 |
| El jugador queda bloqueado                              | Abandono o frustración                    | Cinco pistas acumulativas, gratuitas y disponibles bajo demanda                                                                                      |
| El jugador no distingue evidencia de decoración         | Diagnóstico arbitrario                    | Redundancia entre captura, log, especificación e integridad; pruebas de comprensión antes del cálculo                                                |
| Tom parece un objetivo pasivo                           | Debilita la historia                      | Acción concreta de Tom antes y después de cada incidente                                                                                             |
| La interfaz hace que Ellie parezca inmóvil              | Contradice la puesta en escena            | Laptop visible, sesiones locales y desplazamiento antes de cada incidente                                                                            |
| El hacking parece mágico                                | Pierde credibilidad                       | Permisos limitados, logs, topología y acciones físicas                                                                                               |
| La junta controla una red distribuida demasiado fácil   | Rompe credibilidad                        | Golpe preparado, captura central parcial y nodos locales heterogéneos                                                                                |
| El mapa parece omnisciente                              | El algoritmo elimina incertidumbre humana | Hora, fuente y confianza en cada reporte; cambios posteriores posibles                                                                               |
| Energía y datos usan el mismo modelo                    | Error técnico                             | Tom restaura energía; el flujo sobrevivible se limita a comunicaciones                                                                               |
| El conflicto copia una tragedia real                    | Explotación histórica                     | Lugar ficticio, sin víctimas reales y revisión de sensibilidad                                                                                       |
| La política se vuelve lore                              | Oculta a la pareja                        | Mostrar sólo órdenes y consecuencias que afectan su recorrido                                                                                        |
| El título fuerza una trama mental                       | Contradice el concepto                    | Mantenerlo como identidad estética, sin amnesia ni neurotecnología                                                                                   |
| El reto 4 diluye el clímax emocional                    | HUSH pierde su función                    | El Acto IV termina antes del tramo final; el Acto V queda libre de trabajo técnico y es más largo que el cierre original                             |
| El reto 4 repite al Incidente 1                         | Sensación de relleno                      | La rima es deliberada e invertida: sin paridad garantizada ni checksum central, la confianza se pondera; la spec y las pistas subrayan la diferencia |
| El navegador no sirve WASM con el MIME correcto         | El motor no inicia                        | Smoke HTTP sobre el paquete Nix y estado de error visible                                                                                            |
| La web duplica reglas del motor                         | Dos resultados para una acción            | Validación exclusiva en Odin y prueba de integración contra WASM real                                                                                |
| Varias soluciones correctas son rechazadas              | Frustración                               | Validadores semánticos y solvers de referencia                                                                                                       |

---

## 14. Fuera de alcance del MVP

- combate o sigilo en tiempo real;
- mundo abierto;
- facciones, reputación o árbol moral;
- ciudad procedural;
- multijugador o servicios en línea;
- ejecución, compilación o sandbox de código del jugador;
- IA generativa;
- implantes mentales, recuerdos alterados o copias de conciencia;
- lugar, dictador o víctimas históricas reconocibles;
- escenas gráficas de tortura o ejecución;
- actuación de voz, música o efectos de audio;
- recursos visuales externos;
- editor dentro del juego;
- compatibilidad con navegadores antiguos sin WebAssembly;
- guardado persistente tradicional;
- finales múltiples basados en una elección de color al final.

---

## 15. Definición de terminado

El MVP está terminado cuando:

- `nix flake check` pasa desde el repositorio limpio;
- `nix build` produce el sitio en `result/share/malla-before-the-silence-web/`;
- el paquete contiene `index.html`, assets y `game.wasm`;
- `nix run .` sirve una partida completa;
- no se requiere backend ni acceso a servicios externos durante una partida;
- una partida normal dura entre 40 y 60 minutos, sin contar pausas voluntarias;
- el recorrido representa entre cuatro y cinco horas dentro de la historia;
- los cuatro incidentes se apoyan en mecanismos reales, fuentes documentadas y
  validación semántica;
- la interfaz usa `inspect`, `evidence` y una intervención específica de cada
  sistema; no incluye pseudocódigo, ejemplos resueltos ni puntuaciones;
- ninguna ruta de juego ejecuta código del usuario;
- una semilla reproduce exactamente incidentes y estado;
- errores de formato no castigan al jugador;
- cada incidente ofrece cinco niveles de pistas acumulativas; consultarlas no
  consume tiempo ni exposición;
- Ellie cambia de nodo físico al menos cuatro veces y nunca regresa al anexo;
- Tom cambia de nodo físico al menos tres veces;
- cada acto actualiza la posición o el estado de movimiento de ambos;
- ningún sistema puede usarse fuera de su nodo o cobertura local;
- el certificado de Ellie está limitado por región, rol, llave física y
  caducidad;
- la junta controla servicios centrales, pero no todos los nodos de la MALLA;
- cada ruta muestra hora y confianza de sus datos;
- el tercer incidente modela sólo comunicaciones; Tom restaura la energía
  mediante una acción física separada;
- en el cuarto incidente la mayoría simple es insuficiente y la decisión LLR
  por bit reproduce siempre la trama verdadera con margen verificable;
- el Acto V, HUSH, no contiene expedientes, retos ni comandos nuevos:
  el tramo final es exclusivamente narrativo;
- Tom toma al menos tres acciones que cambian el estado jugable;
- la pareja se reúne físicamente en el final principal;
- el texto del juego nunca identifica el lugar;
- el juego distingue insurrección, golpe y dictadura;
- no aparecen testimonios ni víctimas reales;
- la web es operable con teclado y legible en viewports móviles y amplios;
- toda fuente técnica puede copiarse o descargarse sin decoración;
- `log` permite releer las escenas recientes sin coste;
- cada incidente incluye al menos un evento narrativo asíncrono durante la
  investigación;
- un fallo permite reiniciar el acto con la misma semilla;
- el guion supera una revisión técnica, narrativa e histórica.

---

## 16. Base de investigación

Estas fuentes sirven para comprender estructuras y consecuencias. No autorizan
a trasladar literalmente personas o hechos al juego.

### Redes cívicas y coordinación

- [Project Cybersyn: Chile's Radical Experiment in Cybernetic
  Socialism](https://thereader.mitpress.mit.edu/project-cybersyn-chiles-radical-experiment-in-cybernetic-socialism/):
  red de télex, software estadístico, sala de operaciones y coordinación de
  recursos durante una crisis.
- [Archivo del Proyecto Cybersyn
  1971-1973](https://archivocidoc.uft.cl/index.php/proyecto-cybersyn-1971-1973):
  documentación primaria y contexto archivístico del proyecto.

**Inferencia de diseño:** una red creada para coordinar producción y servicios
es una base histórica más sólida que una “super-IA”. En la ficción, el horror
surge cuando cambian las llaves, los operadores y los objetivos.

### Golpe de Estado y control de comunicaciones

- [11 de septiembre de 1973: Golpe Civil
  Militar](https://www.archivonacional.gob.cl/11-de-septiembre-1973-golpe-civil-militar):
  ataques a comunicaciones y uso decisivo de la radio.
- [Bandos militares,
  1973](https://www.archivonacional.gob.cl/galeria/bandos-militares-cautin-1973):
  ejemplos de toque de queda, restricciones de prensa, detenciones e
  intervención institucional.
- [Armed Forces Statement Closing Radio
  Stations](https://nsarchive.gwu.edu/document/15596-09-armed-forces-statement-closing-radio):
  documento sobre el cierre de emisoras.
- [Museo de la Memoria y los Derechos
  Humanos](https://mmdh.cl/exposiciones/principal):
  contexto sobre estado de sitio, represión y supresión institucional.

**Inferencia de diseño:** tomar antenas, transporte, medios y centros
productivos debe preceder a cualquier explicación ideológica. La interfaz puede
mostrar el golpe a través de cambios operativos verificables.

### Cortes y vigilancia contemporánea

- [Internet shutdowns: trends, causes, legal implications and impacts on human
  rights](https://searchlibrary.ohchr.org/record/32085/files/2022-ShutDownReport.pdf):
  efectos de cortar redes sobre comunicación directa, alertas y servicios
  vitales.
- [OHCHR: surveillance industry and freedom of
  expression](https://www.ohchr.org/en/calls-for-input/report-adverse-effect-surveillance-industry-freedom-expression):
  riesgos de la vigilancia para derechos y libertad de expresión.

**Inferencia de diseño:** perder conectividad no es sólo perder chat. También
elimina avisos, coordinación médica, rutas y capacidad de documentar abusos.

### Tecnología operacional y redes eléctricas

- [NIST SP 800-82 Rev. 3: Guide to Operational Technology
  Security](https://csrc.nist.gov/pubs/sp/800/82/r3/final):
  topologías, segmentación, acceso y requisitos particulares de sistemas que
  interactúan con procesos físicos.
- [NREL: A General Method for Estimating Zonal Transmission Interface
  Limits](https://research-hub.nrel.gov/en/publications/a-general-method-for-estimating-zonal-transmission-interface-limi/):
  importancia de las restricciones físicas y las leyes de Kirchhoff al modelar
  flujo eléctrico.

**Inferencia de diseño:** la laptop de Ellie necesita proximidad, credenciales
acotadas y nodos compatibles. La energía no se modelará como flujo de red:
Tom restaura la alimentación físicamente y Ellie optimiza sólo la red de datos.

### Algoritmos y comunicaciones

- [RFC 8627: RTP Payload Format for Flexible Forward Error Correction
  (FEC)](https://www.rfc-editor.org/info/rfc8627/):
  uso de paridad XOR para generar paquetes de reparación y recuperar pérdidas.
- [NIST: Dijkstra's
  algorithm](https://xlinux.nist.gov/dads/HTML/dijkstraalgo.html).
- [NIST Dictionary of Algorithms and Data
  Structures](https://xlinux.nist.gov/dads/terms.html).
- [NIST: Maximum
  Flow](https://xlinux.nist.gov/dads/HTML/maximumflow.html).
- [NIST: Out-of-coverage communication and frequency
  hopping](https://www.nist.gov/publications/performance-evaluation-lte-device-device-out-coverage-communication-frequency-hopping).

**Inferencia de diseño:** paridad, grafos, flujo de datos y planificación de
canales permiten operaciones pequeñas con una relación auténtica con redes,
logística y comunicación de emergencia. El Incidente 4 se apoya en la misma
familia: la repetición es el código de corrección más simple (la forma
degenerada del FEC por paridad del RFC 8627) y la combinación ponderada por
calidad de señal es práctica estándar de receptores con diversidad, como los
enlaces fuera de cobertura del estudio del NIST ya citado.

### Odin y Nix

- [Odin Overview](https://odin-lang.org/docs/overview/).
- [Odin core:testing](https://pkg.odin-lang.org/core/testing/).
- [NixOS Wiki:
  Flakes](https://wiki.nixos.org/wiki/Flakes).
- [Nixpkgs
  Manual](https://nixos.org/manual/nixpkgs/stable/).
- [Reproducible Builds with
  Nix](https://reproducible.nixos.org/).

### Referencia musical

- [Muse, “Hush” en Official
  Charts](https://www.officialcharts.com/songs/muse-hush/).
- [Anuncio de `The Wow! Signal` de Warner
  Records](https://press.warnerrecords.com/sites/g/files/g2000014901/files/2026-03/ANNOUNCE%20NEW%20ALBUM%20THE%20WOW%20SIGNAL.pdf).

Estas referencias fijan el tono y la estructura de investigación. La siguiente
etapa no es añadir más lore: es escribir el transcript completo y comprobar que
la relación funciona antes de programar el motor.
