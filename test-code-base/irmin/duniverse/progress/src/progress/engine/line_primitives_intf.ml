(*————————————————————————————————————————————————————————————————————————————
   Copyright (c) 2020–2021 Craig Ferguson <me@craigfe.io>
   Distributed under the MIT license. See terms at the end of this file.
  ————————————————————————————————————————————————————————————————————————————*)

open! Import

module type Counter = sig
  type t

  val counter : unit -> t
  val count : t -> Mtime.span
end

module Types = struct
  type event =
    [ `report (* User has supplied a reported value. *)
    | `rerender (* Renderer wants a re-display. *)
    | `tick (* User has requested a "tick" (e.g. to update spinners). *)
    | `finish (* The bar or display has been finalised. *) ]
end

(** The DSL of progress bar segments. *)
module type S = sig
  type 'a t
  (** The type of segments of progress bars that display reported values of type
      ['a]. *)

  include module type of Types

  type theta := Line_buffer.t -> event -> unit
  type 'a alpha := Line_buffer.t -> event -> 'a -> unit

  val noop : unit -> _ t
  val theta : width:int -> theta -> _ t

  val alpha :
       width:int
    -> initial:[ `Theta of Line_buffer.t -> unit | `Val of 'a ]
    -> 'a alpha
    -> 'a t

  val alpha_unsized :
       initial:
         [ `Theta of width:(unit -> int) -> Line_buffer.t -> int | `Val of 'a ]
    -> (width:(unit -> int) -> Line_buffer.t -> event -> 'a -> int)
    -> 'a t

  val array : 'a t array -> 'a t
  val pair : ?sep:unit t -> 'a t -> 'b t -> ('a * 'b) t
  val contramap : f:('a -> 'b) -> 'b t -> 'a t
  val on_finalise : 'a -> 'a t -> 'a t

  val of_pp :
    width:int -> initial:'a -> (Format.formatter -> event -> 'a -> unit) -> 'a t
  (** [of_pp ~width pp] is a segment that uses the supplied fixed-width
      pretty-printer to render the value. The pretty-printer must never emit
      newline characters. *)

  val conditional : ('a -> bool) -> 'a t -> 'a t
  (** [conditional pred s] has the same output format as [s], but is only passes
      reported values down to [s] when they satisfy [pred]. *)

  (** {2:stateful Stateful segments} *)

  val periodic : int -> 'a t -> 'a t
  (** [periodic n s] has the same output format as [s], but only passes reported
      values down to [s] on every [n]-th call. This is useful when progress is
      being reported from a hot-loop, where the cost of rendering is
      non-negligible. *)

  val accumulator : ('a -> 'a -> 'a) -> 'a -> 'a t -> 'a t
  (** [accumulator combine zero s] has the same output format [s]. *)

  val stateful : (unit -> 'a t) -> 'a t
  (** [stateful f] is a segment that behaves as [f ()] for any given render,
      allowing [f] to initialise any display state at the start of the rendering
      process. *)

  (** {2:boxes Dynamically-sized segments} *)

  (** Certain segments can have their size determined dynamically by being
      wrapped inside one of the following boxes: *)

  val box_dynamic :
    ?pad:[ `left | `right | `none ] -> (unit -> int) -> 'a t -> 'a t
  (** [box w] is a box that wraps a dynamically-sized segment and sets it to
      have size [w ()] on each tick. *)

  val box_fixed : ?pad:[ `left | `right | `none ] -> int -> 'a t -> 'a t
  (** [box-fixed n s] fixes the size of the dynamic segment [s] to be [n]. *)
end

module type Line_primitives = sig
  module type S = S

  include S

  module Compiled : sig
    type 'a t

    val pp_dump : Format.formatter -> 'a t -> unit
  end

  val compile : 'a t -> 'a Compiled.t

  val update :
    'a Compiled.t -> (unconditional:bool -> Line_buffer.t -> int) Staged.t

  val report : 'a Compiled.t -> (Line_buffer.t -> 'a -> int) Staged.t
  val tick : 'a Compiled.t -> (Line_buffer.t -> int) Staged.t
  val finalise : 'a Compiled.t -> (Line_buffer.t -> int) Staged.t
end

(*————————————————————————————————————————————————————————————————————————————
   Copyright (c) 2020–2021 Craig Ferguson <me@craigfe.io>

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
  ————————————————————————————————————————————————————————————————————————————*)
