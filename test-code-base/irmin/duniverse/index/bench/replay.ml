(*
 * Copyright (c) 2018-2021 Tarides <contact@tarides.com>
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

open Common
module Int63 = Optint.Int63

module Encoding = struct
  module Hash : sig
    type t

    val t : t Repr.t
    val short_hash : t -> int
    val hash_size : int
    val hash : string Digestif.iter -> t
  end = struct
    module H = Digestif.Make_BLAKE2B (struct
      let digest_size = 32
    end)

    type t = H.t

    let prefix = "\079\199" (* Co(52) *)

    let pp ppf t =
      let s = H.to_raw_string t in
      Tezos_base58.pp ppf (Tezos_base58.encode ~prefix s)

    let of_b58 : string -> (t, [ `Msg of string ]) result =
     fun x ->
      match Tezos_base58.decode ~prefix (Base58 x) with
      | Some x -> Ok (H.of_raw_string x)
      | None -> Error (`Msg "Failed to read b58check_encoding data")

    let short_hash_string = Repr.(unstage (short_hash string))
    let short_hash ?seed t = short_hash_string ?seed (H.to_raw_string t)

    let t : t Repr.t =
      Repr.map ~pp ~of_string:of_b58
        Repr.(string_of (`Fixed H.digest_size))
        ~short_hash H.of_raw_string H.to_raw_string

    let short_hash =
      let f = short_hash_string ?seed:None in
      fun t -> f (H.to_raw_string t)

    let hash_size = H.digest_size
    let hash = H.digesti_string
  end

  module Key : Index.Key.S with type t = Hash.t = struct
    type t = Hash.t [@@deriving repr]

    let hash = Repr.(unstage (short_hash Hash.t)) ?seed:None
    let hash_size = 30
    let equal = Repr.(unstage (equal Hash.t))
    let encode = Repr.(unstage (to_bin_string Hash.t))
    let encoded_size = Hash.hash_size
    let decode_bin = Repr.(unstage (decode_bin Hash.t))
    let decode s off = decode_bin s (ref off)
  end

  module Val = struct
    type t = Int63.t * int * char [@@deriving repr]

    let to_bin_string = Repr.(unstage (to_bin_string (triple int63 int32 char)))
    let encode (off, len, kind) = to_bin_string (off, Int32.of_int len, kind)
    let decode_bin = Repr.(unstage (decode_bin (triple int63 int32 char)))

    let decode s off =
      let off, len, kind = decode_bin s (ref off) in
      (off, Int32.to_int len, kind)

    let encoded_size = (64 / 8) + (32 / 8) + 1
  end
end

let decoded_seq_of_encoded_chan_with_prefixes :
      'a. 'a Repr.ty -> in_channel -> 'a Seq.t =
 fun repr channel ->
  let decode_bin = Repr.decode_bin repr |> Repr.unstage in
  let decode_prefix = Repr.(decode_bin int32 |> unstage) in
  let produce_op () =
    try
      (* First read the prefix *)
      let prefix = really_input_string channel 4 in
      let pos_ref = ref 0 in
      let len = decode_prefix prefix pos_ref in
      assert (!pos_ref = 4);
      let len = Int32.to_int len in
      (* Then read the repr *)
      pos_ref := 0;
      let content = really_input_string channel len in
      let op = decode_bin content pos_ref in
      assert (!pos_ref = len);
      Some (op, ())
    with End_of_file -> None
  in
  Seq.unfold produce_op ()

type config = { nb_ops : int; trace_data_file : string; root : string }

module Trace = struct
  type key = string [@@deriving repr]

  type op =
    | Clear
    | Flush
    | Mem of key * bool
    | Find of key * bool
    | Ro_mem of key * bool
    | Ro_find of key * bool
    | Add of key * (Int63.t * int * char)
  [@@deriving repr]

  let open_ops_sequence path : op Seq.t =
    let chan = open_in_bin path in
    decoded_seq_of_encoded_chan_with_prefixes op_t chan
end

module Benchmark = struct
  type result = { time : Mtime.Span.t; size : int }

  let run config f =
    let res, time = with_timer f in
    let size = FSHelper.get_size config.root in
    ({ time; size }, res)

  let get_maxrss () =
    let usage = Rusage.(get Self) in
    let ( / ) = Int64.div in
    usage.maxrss / 1024L / 1024L

  let pp_results ppf result =
    Format.fprintf ppf "Total time: %a; Size on disk: %d M; Maxrss: %Ld"
      Mtime.Span.pp result.time result.size (get_maxrss ())
end

module type S = sig
  include Index.S

  val v : string -> t
  val close : t -> unit
end

module Index_lib = Index

module Index = struct
  module Index =
    Index_unix.Make (Encoding.Key) (Encoding.Val) (Index.Cache.Unbounded)

  include Index

  let cache = Index.empty_cache ()
  let v root = Index.v ~cache ~readonly:false ~fresh:true ~log_size:500_000 root
  let close t = Index.close t
end

let hash_of_string = Repr.of_string Encoding.Hash.t

module Bench_suite
    (Store : S
               with type key = Encoding.Hash.t
                and type value = Int63.t * int * char) =
struct
  let key_to_hash k =
    match hash_of_string k with
    | Ok k -> k
    | Error (`Msg m) -> Fmt.failwith "error decoding hash %s" m

  let add_operation store op_seq nb_ops () =
    with_progress_bar ~message:"Replaying trace" ~n:nb_ops ~unit:"operations"
    @@ fun progress ->
    let rec aux op_seq i =
      if i >= nb_ops then i
      else
        match op_seq () with
        | Seq.Nil -> i
        | Cons (op, op_seq) ->
            let () =
              match op with
              | Trace.Flush -> Store.flush store
              | Clear -> Store.clear store
              | Mem (k, b) ->
                  let k = key_to_hash k in
                  let b' = Store.mem store k in
                  if b <> b' then
                    Fmt.failwith "Operation mem %a expected %b got %b"
                      (Repr.pp Encoding.Key.t) k b b'
              | Find (k, b) ->
                  let k = key_to_hash k in
                  let b' =
                    match Store.find store k with
                    | (_ : Store.value) -> true
                    | exception Not_found -> false
                  in
                  if b <> b' then
                    Fmt.failwith "Operation find %a expected %b got %b"
                      (Repr.pp Encoding.Key.t) k b b'
              | Add (k, v) ->
                  let k = key_to_hash k in
                  Store.replace store k v
              | Ro_mem _ | Ro_find _ -> ()
            in
            progress Int64.one;
            aux op_seq (i + 1)
    in
    aux op_seq 0

  let run_read_trace config =
    let op_seq = Trace.open_ops_sequence config.trace_data_file in
    let store = Store.v config.root in

    let result, nb_ops =
      add_operation store op_seq config.nb_ops |> Benchmark.run config
    in

    let () = Store.close store in

    fun ppf ->
      Format.fprintf ppf "Tezos trace for %d nb_ops @\nResults: @\n%a@\n" nb_ops
        Benchmark.pp_results result
end

module Bench = Bench_suite (Index)

let main nb_ops trace_data_file =
  Printexc.record_backtrace true;
  Random.self_init ();
  let root = "_bench_replay" in
  FSHelper.rm_dir root;
  let config = { trace_data_file; root; nb_ops } in
  let results = Bench.run_read_trace config in
  Logs.app (fun l -> l "%t@." results)

open Cmdliner

let nb_ops =
  let doc =
    Arg.info ~doc:"Number of operations to read from trace." [ "ops" ]
  in
  Arg.(value @@ opt int 2 doc)

let trace_data_file =
  let doc =
    Arg.info ~docv:"PATH" ~doc:"Trace of Tezos operations to be replayed." []
  in
  Arg.(required @@ pos 0 (some string) None doc)

let main_term =
  Term.(
    const (fun () -> main)
    $ Index_lib.Private.Logs.setup_term (module Mtime_clock)
    $ nb_ops
    $ trace_data_file)

let deprecated_info = (Term.info [@alert "-deprecated"])
let deprecated_exit = (Term.exit [@alert "-deprecated"])
let deprecated_eval = (Term.eval [@alert "-deprecated"])

let () =
  let man =
    [
      `S "DESCRIPTION";
      `P
        "Benchmarks for index operations. Requires traces of operations\n\
        \         download them (`wget trace.repr`) from: ";
      `P
        "Trace with $(b,401,253,899) operations \
         http://data.tarides.com/index/trace_401253899.repr";
      `P
        "Trace with $(b,544,766,125) operations \
         http://data.tarides.com/index/trace_544766125.repr";
    ]
  in
  let info =
    deprecated_info ~man
      ~doc:"Replay index operations done by the bootstrapping of a tezos node"
      "replay-index"
  in
  deprecated_exit @@ deprecated_eval (main_term, info)
