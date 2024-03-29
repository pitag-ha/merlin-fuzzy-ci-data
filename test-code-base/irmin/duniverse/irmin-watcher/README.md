## irmin-watcher — Portable Irmin watch backends using FSevents or Inotify

0.5.0

irmin-watcher implements [Irmin's watch hooks][watch] for various OS,
using FSevents in OSX and Inotify on Linux.

irmin-watcher is distributed under the ISC license.

[watch]: http://mirage.github.io/irmin/Irmin.Private.Watch.html

## Installation

irmin-watcher can be installed with `opam`:

    opam install irmin-watcher

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Documentation

The documentation and API reference is automatically generated by
`ocamldoc` from the interfaces. It can be consulted [online][doc]
and there is a generated version in the `doc` directory of the
distribution.

[doc]: https://samoht.github.io/irmin-watcher/
