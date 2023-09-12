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

open Ctypes
include Types_intf

module Struct = struct
  type config = unit
  type repo = unit
  type store = unit
  type ty = unit
  type value = unit
  type metadata = unit
  type contents = unit
  type path = unit
  type tree = unit
  type commit = unit
  type hash = unit
  type info = unit
  type irmin_string = unit
  type path_array = unit
  type commit_array = unit
  type branch_array = unit
  type commit_key = unit
  type kinded_key = unit
  type remote = unit
end

let config : Struct.config ptr typ = ptr (typedef void "IrminConfig")
let repo : Struct.repo ptr typ = ptr (typedef void "IrminRepo")
let store : Struct.store ptr typ = ptr (typedef void "Irmin")
let ty : Struct.ty ptr typ = ptr (typedef void "IrminType")
let value : Struct.value ptr typ = ptr (typedef void "IrminValue")
let metadata : Struct.metadata ptr typ = ptr (typedef void "IrminMetadata")
let contents : Struct.metadata ptr typ = ptr (typedef void "IrminContents")
let path : Struct.path ptr typ = ptr (typedef void "IrminPath")
let tree : Struct.tree ptr typ = ptr (typedef void "IrminTree")
let commit : Struct.commit ptr typ = ptr (typedef void "IrminCommit")
let hash : Struct.hash ptr typ = ptr (typedef void "IrminHash")
let info : Struct.info ptr typ = ptr (typedef void "IrminInfo")
let remote : Struct.remote ptr typ = ptr (typedef void "IrminRemote")

let irmin_string : Struct.irmin_string ptr typ =
  ptr (typedef void "IrminString")

let path_array : Struct.path_array ptr typ = ptr (typedef void "IrminPathArray")

let commit_array : Struct.commit_array ptr typ =
  ptr (typedef void "IrminCommitArray")

let branch_array : Struct.branch_array ptr typ =
  ptr (typedef void "IrminBranchArray")

let commit_key : Struct.commit_key ptr typ = ptr (typedef void "IrminCommitKey")
let kinded_key : Struct.kinded_key ptr typ = ptr (typedef void "IrminKindedKey")
