# MALLA: BEFORE THE SILENCE — web

Interfaz SvelteKit del juego. El navegador presenta la historia y las
evidencias; el estado, las reglas y la validación de los acertijos continúan en
Odin, compilado a WebAssembly.

## Desarrollo

Desde este directorio:

```sh
pnpm install
pnpm run dev
```

`dev` recompila primero `../src` como `static/game.wasm` y después inicia Vite.
Se puede seleccionar una instancia determinista con `?seed=<u64>`.

## Validación

```sh
pnpm run validate
```

La salida de producción es completamente estática y queda en `build/`.
