# machin-web-demo-reactive — signals, computed, and a keyed list, in machin

A reactive list whose **state and view logic live entirely in machin**, compiled
to WebAssembly, with **fine-grained reactivity**: a **computed** sum, live
bindings, and a **keyed list** that emits only the DOM deltas — no `innerHTML`
replacement, no virtual-DOM diff. It's the Solid/Leptos model, in MFL.

![screenshot](screenshot.png)

## The model

[`reactive.src`](reactive.src) (from
[machin/framework](https://github.com/javimosch/machin/tree/main/framework)) is a
~200-line runtime:

- **`signal(v)`** holds state; **`get`** / **`set`** read & write it (a `set` only
  notifies if the value changed).
- **`computed(func(){ return … })`** is a memoized derived signal — here, the sum
  of the list. It recomputes only when a signal it reads changes.
- **`slot(name, compute)`** returns the markup for a reactive text node and wires
  its binding; **`list(name, keys, item)`** does the same for a keyed list (`keys()`
  returns the ordered keys as a CSV string, `item(key)` renders an item once).
- **`mount(root, html)`** sets the root's HTML once, then activates the queued
  bindings/lists. So the component declares its **markup and reactivity together**
  — no hand-written HTML skeleton, no manual `data-s` wiring.

Every reaction auto-tracks the signals it reads, so a change recomputes only the
affected reactions, and only changed text/keys hit the DOM. A keyed list emits only
`list_insert` (new) / `list_remove` (gone) / `list_order` (reorder).

## What "fine-grained" buys you (verified)

| action | patches emitted |
|---|---|
| `add 10` | `sum=10, count=1, insert #1, order 1` |
| `add 3` | `sum=13, count=2, insert #2, order 1,2`  *(item 1 not re-rendered)* |
| `sort ↑` | `order 2,3,1`  *(**only** a reorder — sum unchanged, no item re-render)* |
| `pop` | `sum=…, count=…, remove #k, order …` |

Sorting a list of N items moves N DOM nodes and recomputes nothing else; the
`sum` only patches when it actually changes.

## The component (`app.src`)

The component declares its markup and reactive slots together, then mounts it —
`index.html` is just `<div id="app"></div>`:

```go
export func start() {
    ver = signal(0)
    sum_sig = computed(func() {          // derived: the sum, memoized
        get(ver)  s := 0  i := 0
        while i < n { s = s + vals[i]  i = i + 1 }
        return s
    })
    mount("app",
        "<div class=stats>sum: " + slot("sum", func() { return str(get(sum_sig)) }) +
        " · count: " + slot("count", func() { get(ver)  return str(n) }) + "</div>" +
        list("items",                     // keyed list
            func() { get(ver)  return csv(ids) },
            func(id) { return "<b>" + str(val_of(id)) + "</b>" }))
}
```

## Build & run

Needs `machin` (**v0.54.0+**) and [`zig`](https://ziglang.org).

```sh
./build.sh                       # → app.wasm
python3 -m http.server 8000      # serve over http (not file://)
# open http://localhost:8000/
```

The JS host is a few lines — decode the slot/key/html strings from wasm memory and
apply each op (`dom_patch` / `list_insert` / `list_remove` / `list_order`). It also
includes a tiny **no-op WASI shim**: indirect closure calls keep wasi-libc's
float-format symbols in the binary; they're imported but never called.

## What's next

This has the reactive core *and* templating (signals, computed, keyed lists, and
`mount`/`slot`/`list` so a component owns its markup). Beyond it: composing many
such components into a real app, and reusing a server-rendered DOM on hydration.
See the [web north star](https://github.com/javimosch/machin/blob/main/docs/NORTH-STAR-WEB.md).

## License

MIT
