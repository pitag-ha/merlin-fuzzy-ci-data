(*
 * Copyright (c) 2017 Christiano F. Haesbaert <haesbaert@haesbaert.org>
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

open Util

(*
 * Channel entry
 *)

type state = Open | Sent_close

type channel_end = {
  id       : int32;
  win      : int32;
  max_pkt  : int32;
}

type channel = {
  us    : channel_end;
  them  : channel_end;
  state : state;
  tosend: Cstruct.t;
}

let compare a b =
  Int32.compare a.us.id b.us.id

type t = channel

module Ordered = struct
  type t = channel
  let compare = compare
end

let make_end id win max_pkt = { id; win; max_pkt }

let make ~us ~them = { us; them; state = Open; tosend = Cstruct.create 0 }

(* Returns new t, data normalized, and adjust window if <> zero *)
let input_data t data =
  (* Normalize data, discard if greater than window *)
  let len = min (Cstruct.length data |> Int32.of_int) t.us.win in
  let data, left = Cstruct.split data (Int32.to_int len) in
  if Cstruct.length left > 0 then
    Printf.printf "channel input_data: discarding %d bytes (window size)\n%!"
      (Cstruct.length left);
  let new_win = Int32.sub t.us.win len in
  let* () = guard Int32.(new_win >= zero) "window underflow" in
  let win, adjust =
    if new_win < Ssh.channel_win_adj_threshold then
      Ssh.channel_win_len, Int32.sub Ssh.channel_win_len new_win
    else
      new_win, Int32.zero
  in
  let* () = guard (Int32.(adjust >= zero)) "adjust underflow" in
  assert Int32.(adjust >= zero);
  let t = { t with us = { t.us with win } } in
  let msg = if adjust <> Int32.zero then
      Some (Ssh.Msg_channel_window_adjust (t.them.id, adjust))
    else
      None
  in
  Ok (t, data, msg)

let output_data t data =
  let fragment data =
    let max_pkt = Int32.to_int t.them.max_pkt in
    let i =
      Cstruct.iter
        (fun buf ->
           if (Cstruct.length buf) = 0 then
             None
           else
             Some (min (Cstruct.length buf) max_pkt))
        (fun buf -> buf)
        data
    in
    Cstruct.fold (fun frags frag ->
        Ssh.Msg_channel_data (t.them.id, frag) :: frags)
      i [] |> List.rev
  in
  let tosend = cs_join t.tosend data in
  let len = min (Cstruct.length tosend) (Int32.to_int t.them.win) in
  let data, tosend = Cstruct.split tosend len in
  let win = Int32.sub t.them.win (Int32.of_int len) in
  let* () = guard Int32.(win >= zero) "window underflow" in
  let t = { t with tosend; them = { t.them with win } } in
  Ok (t, fragment data)

let adjust_window t len =
  let win = Int32.add t.them.win len in
  (* XXX this does not handle up to 4GB correctly. *)
  let* () = guard Int32.(win > zero) "window overflow" in
  let data = t.tosend in
  let t = { t with tosend = Cstruct.create 0; them = { t.them with win } } in
  output_data t data

(*
 * Channel database
 *)

module Channel_map = Map.Make(Int32)

type db = channel Channel_map.t

let empty_db = Channel_map.empty

let is_empty = Channel_map.is_empty

(* Find the next available free channel *)
let next_free db =
  let rec linear lkey = function
    | [] -> None
    | hd :: tl ->
      let key = fst hd in
      (* Find a hole *)
      if Int32.succ lkey <> key then
        Some (Int32.succ lkey)
      else
        linear key tl
  in
  match Channel_map.max_binding_opt db with
  | None -> Some Int32.zero
  | Some (key, _) ->
    (* If max binding is not max key *)
    if key <> (Int32.of_int (Ssh.max_channels - 1)) then
      Some (Int32.succ key)
    else
      linear Int32.minus_one (Channel_map.bindings db)

let add ~id ~win ~max_pkt db =
  (* Find the next available free channel *)
  match next_free db with
  | None -> Error `No_channels_left
  | Some key ->
    let them = make_end id win max_pkt in
    let us = make_end key Ssh.channel_win_len Ssh.channel_max_pkt_len in
    let c = make ~us ~them in
    Ok (c, Channel_map.add key c db)

let update c db = Channel_map.add c.us.id c db

let remove id db = Channel_map.remove id db

let lookup id db = Channel_map.find_opt id db

let id c = c.us.id

let their_id c = c.them.id
