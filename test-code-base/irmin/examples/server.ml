(*
 * Copyright (c) 2018-2022 Tarides <contact@tarides.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt.Syntax
module Store = Irmin_mem.KV.Make (Irmin.Contents.String)
module Server = Irmin_server_unix.Make (Store)

let info () = Irmin.Info.Default.empty

let init () =
  let* repo = Store.Repo.v (Irmin_mem.config ()) in
  let* main = Store.main repo in
  let+ () = Store.set_exn ~info main [ "foo" ] "bar" in
  ()

let main () =
  let uri = Uri.of_string Sys.argv.(1) in
  let config = Irmin_mem.config () in
  let dashboard = `TCP (`Port 1234) in
  let* server = Server.v ~uri ~dashboard config in
  let () = Format.printf "Listening on %a@." Uri.pp uri in
  Server.serve server

let () =
  Lwt_main.run
  @@ let* () = init () in
     main ()
