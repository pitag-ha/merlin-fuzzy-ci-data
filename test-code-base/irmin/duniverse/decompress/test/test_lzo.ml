let pp_chr =
  Fmt.using (function '\032' .. '\126' as x -> x | _ -> '.') Fmt.char

let pp_scalar :
    type buffer.
    get:(buffer -> int -> char) -> length:(buffer -> int) -> buffer Fmt.t =
 fun ~get ~length ppf b ->
  let l = length b in
  for i = 0 to l / 16 do
    Fmt.pf ppf "%08x: " (i * 16)
    ; let j = ref 0 in
      while !j < 16 do
        if (i * 16) + !j < l then
          Fmt.pf ppf "%02x" (Char.code @@ get b ((i * 16) + !j))
        else Fmt.pf ppf "  "
        ; if !j mod 2 <> 0 then Fmt.pf ppf " "
        ; incr j
      done
      ; Fmt.pf ppf "  "
      ; j := 0
      ; while !j < 16 do
          if (i * 16) + !j < l then
            Fmt.pf ppf "%a" pp_chr (get b ((i * 16) + !j))
          else Fmt.pf ppf " "
          ; incr j
        done
      ; Fmt.pf ppf "@\n"
  done

let pp_string = pp_scalar ~get:String.get ~length:String.length
let str = Alcotest.testable pp_string String.equal

let test_lzo_0 () =
  Alcotest.test_case "random" `Quick @@ fun () ->
  let expect =
    [
      "\x4f\x07\x7e\x4e\x2f\x7d\xc2\x99\xf9\xdb\x1c\xb9\x4a\x74\x29\xd4"
    ; "\x95\xd4\x63\xce\x2f\x00\x03\x40\x48\xd4\x7b\x26\x6c\xf2\x4f\xea"
    ; "\xeb\x85\xf4\x7c\xd9\xbb\x90\x0b\x3f\x69\xa5\xa3\xa6\x19\x76\x39"
    ; "\x41\x88\xd8\x87\x2f\x1d\xa7\x80\xe8\xe3\x0c\x5e\x16\x27\xe4\xd2"
    ; "\xcd\x92\x48\x3a\xf1\x99\x16\xb2\xe1\x82\xb6\x5d\x65\xc7\xba\x15"
    ; "\x95\xcf\xa9\xdf\x98\x09\x5f\x29\x9c\x0b\x13\x56\xaa\x3e\x7d\xc6"
    ; "\x55\x3f\x67\x81\xe3\x0b\x2b\xab\xf4\x5c\x8e\x20\xeb\xc7\x7a\x3b"
    ; "\x3a\x29\xf4\x79\x65\x3b\xf8\xdd\xef\x19\xae\x20\x3e\xe3\x71\x86"
    ] in
  let input =
    [
      "\x91\x4f\x07\x7e\x4e\x2f\x7d\xc2\x99\xf9\xdb\x1c\xb9\x4a\x74\x29"
    ; "\xd4\x95\xd4\x63\xce\x2f\x00\x03\x40\x48\xd4\x7b\x26\x6c\xf2\x4f"
    ; "\xea\xeb\x85\xf4\x7c\xd9\xbb\x90\x0b\x3f\x69\xa5\xa3\xa6\x19\x76"
    ; "\x39\x41\x88\xd8\x87\x2f\x1d\xa7\x80\xe8\xe3\x0c\x5e\x16\x27\xe4"
    ; "\xd2\xcd\x92\x48\x3a\xf1\x99\x16\xb2\xe1\x82\xb6\x5d\x65\xc7\xba"
    ; "\x15\x95\xcf\xa9\xdf\x98\x09\x5f\x29\x9c\x0b\x13\x56\xaa\x3e\x7d"
    ; "\xc6\x55\x3f\x67\x81\xe3\x0b\x2b\xab\xf4\x5c\x8e\x20\xeb\xc7\x7a"
    ; "\x3b\x3a\x29\xf4\x79\x65\x3b\xf8\xdd\xef\x19\xae\x20\x3e\xe3\x71"
    ; "\x86\x11\x00\x00"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string ~off:0 ~len:(String.length input) input in
  let output = Bigstringaf.create (Bigstringaf.length input) in
  match Lzo.uncompress input output with
  | Ok output ->
    Alcotest.(check str)
      "result"
      (Bigstringaf.to_string output)
      (String.concat "" expect)
  | Error err -> Alcotest.failf "Invalid LZO input: %a" Lzo.pp_error err

let test_lzo_1 () =
  Alcotest.test_case "simple test" `Quick @@ fun () ->
  let input = "Salut les copains!" in
  let output = Bigstringaf.create 128 in
  let wrkmem = Lzo.make_wrkmem () in
  let len =
    Lzo.compress
      (Bigstringaf.of_string ~off:0 ~len:(String.length input) input)
      output wrkmem in
  let res = Bigstringaf.sub output ~off:0 ~len in
  match Lzo.uncompress_with_buffer res with
  | Ok res -> Alcotest.(check str) "result" res input
  | Error err -> Alcotest.failf "Invalid LZO input: %a" Lzo.pp_error err

let test_lzo_2 () =
  Alcotest.test_case "ensure it fails without exception" `Quick @@ fun () ->
  match
    Lzo.uncompress_with_buffer
      (Bigstringaf.of_string "\x00\x00\x11\x00\x00" ~off:0 ~len:5)
  with
  | Ok _ -> Alcotest.failf "An error is expected"
  | Error err ->
    let msg =
      match err with
      | `Malformed msg -> Fmt.str "malformed: %s" msg
      | `Invalid_argument msg -> Fmt.str "invalid argument: %s" msg
      | `Invalid_dictionary -> Fmt.str "invalid dictionary" in
    Alcotest.(check pass) msg () ()

let output_lzo_3 =
  [
    "\x45\x00\x05\xdc\xce\x19\x20\x00\x3a\x01\x82\x04\x2e\x65\x89\xb5"
  ; "\x2e\xf6\x23\xf3\x08\x00\xbd\x88\x32\x44\x00\x01\x8f\xc2\x22\x5d"
  ; "\x00\x00\x00\x00\x08\x5c\x04\x00\x00\x00\x00\x00\x10\x11\x12\x13"
  ; "\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23"
  ; "\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33"
  ; "\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43"
  ; "\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53"
  ; "\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63"
  ; "\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73"
  ; "\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83"
  ; "\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93"
  ; "\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3"
  ; "\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3"
  ; "\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3"
  ; "\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3"
  ; "\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3"
  ; "\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3"
  ; "\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x00\x01\x02\x03"
  ; "\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13"
  ; "\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23"
  ; "\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33"
  ; "\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43"
  ; "\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53"
  ; "\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63"
  ; "\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73"
  ; "\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83"
  ; "\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93"
  ; "\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3"
  ; "\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3"
  ; "\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3"
  ; "\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3"
  ; "\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3"
  ; "\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3"
  ; "\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x00\x01\x02\x03"
  ; "\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13"
  ; "\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23"
  ; "\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33"
  ; "\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43"
  ; "\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53"
  ; "\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63"
  ; "\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73"
  ; "\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83"
  ; "\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93"
  ; "\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3"
  ; "\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3"
  ; "\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3"
  ; "\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3"
  ; "\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3"
  ; "\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3"
  ; "\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x00\x01\x02\x03"
  ; "\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13"
  ; "\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23"
  ; "\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33"
  ; "\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43"
  ; "\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53"
  ; "\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63"
  ; "\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73"
  ; "\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83"
  ; "\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93"
  ; "\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3"
  ; "\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3"
  ; "\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3"
  ; "\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3"
  ; "\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3"
  ; "\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3"
  ; "\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x00\x01\x02\x03"
  ; "\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13"
  ; "\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23"
  ; "\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33"
  ; "\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43"
  ; "\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53"
  ; "\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63"
  ; "\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73"
  ; "\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83"
  ; "\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93"
  ; "\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3"
  ; "\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3"
  ; "\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3"
  ; "\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3"
  ; "\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3"
  ; "\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3"
  ; "\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x00\x01\x02\x03"
  ; "\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13"
  ; "\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23"
  ; "\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33"
  ; "\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43"
  ; "\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53"
  ; "\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63"
  ; "\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73"
  ; "\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83"
  ; "\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93"
  ; "\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3"
  ; "\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3"
  ; "\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
  ]

let test_lzo_3 () =
  Alcotest.test_case "ping -s 10000 46.246.35.243" `Quick @@ fun () ->
  let input =
    [
      "\x00\x16\x45\x00\x05\xdc\xce\x19\x20\x00\x3a\x01\x82\x04\x2e\x65"
    ; "\x89\xb5\x2e\xf6\x23\xf3\x08\x00\xbd\x88\x32\x44\x00\x01\x8f\xc2"
    ; "\x22\x5d\x00\x00\x00\x00\x08\x5c\x04\x00\x7c\x00\x00\xf3\x10\x11"
    ; "\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21"
    ; "\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31"
    ; "\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41"
    ; "\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51"
    ; "\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61"
    ; "\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71"
    ; "\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81"
    ; "\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91"
    ; "\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1"
    ; "\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1"
    ; "\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1"
    ; "\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1"
    ; "\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1"
    ; "\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1"
    ; "\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x00\x01"
    ; "\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11"
    ; "\x12\x13\x14\x20\x00\x00\x00\x00\x7f\xfc\x03\x0c\xb1\xb2\xb3\xb4"
    ; "\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\x11\x00\x00"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string input ~off:0 ~len:(String.length input) in
  match Lzo.uncompress_with_buffer input with
  | Ok str ->
    Alcotest.(check string) "output" str (String.concat "" output_lzo_3)
  | Error _ -> Alcotest.failf "Invalid LZO input"

let test_lzo_4 () =
  Alcotest.test_case "handle empty" `Quick @@ fun () ->
  let input = Bigstringaf.of_string ~off:0 ~len:3 "\x11\x00\x00" in
  match Lzo.uncompress_with_buffer input with
  | Ok str -> Alcotest.(check string) "empty" str ""
  | Error _ -> Alcotest.failf "Invalid LZO input"

let output_lzo_5 =
  [
    "\x45\x00\x00\xb2\xb5\xd4\x00\x00\x32\x11\x69\x78\xb2\x00\x64\xfd"
  ; "\x2e\xf6\x22\xfb\xfa\xd3\x00\x35\x00\x9e\x2c\xfa\xe2\x6b\x01\x20"
  ; "\x00\x01\x00\x00\x00\x00\x00\x01\x0a\x61\x62\x63\x64\x65\x66\x67"
  ; "\x68\x69\x6a\x0a\x31\x32\x33\x34\x35\x36\x37\x38\x39\x30\x0a\x61"
  ; "\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x0a\x31\x32\x33\x34\x35\x36"
  ; "\x37\x38\x39\x30\x0a\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x0a"
  ; "\x31\x32\x33\x34\x35\x36\x37\x38\x39\x30\x0a\x61\x62\x63\x64\x65"
  ; "\x66\x67\x68\x69\x6a\x0a\x31\x32\x33\x34\x35\x36\x37\x38\x39\x30"
  ; "\x0a\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x0a\x31\x32\x33\x34"
  ; "\x35\x36\x37\x38\x39\x30\x00\x00\x01\x00\x01\x00\x00\x29\x10\x00"
  ; "\x00\x00\x00\x00\x00\x0c\x00\x0a\x00\x08\x4e\xcd\xdc\xdd\xc2\x75"
  ; "\x25\x98"
  ]

let test_lzo_5 () =
  Alcotest.test_case "dig/dns: don't crash" `Quick @@ fun () ->
  let input =
    [
      "\x00\x2c\x45\x00\x00\xb2\xb5\xd4\x00\x00\x32\x11\x69\x78\xb2\x00"
    ; "\x64\xfd\x2e\xf6\x22\xfb\xfa\xd3\x00\x35\x00\x9e\x2c\xfa\xe2\x6b"
    ; "\x01\x20\x00\x01\x00\x00\x00\x00\x00\x01\x0a\x61\x62\x63\x64\x65"
    ; "\x66\x67\x68\x69\x6a\x0a\x31\x32\x33\x34\x35\x36\x37\x38\x39\x30"
    ; "\x20\x37\x57\x00\x00\x00\x01\x60\x0f\x00\x03\x29\x10\x00\x00\x00"
    ; "\x00\x00\x00\x0c\x00\x0a\x00\x08\x4e\xcd\xdc\xdd\xc2\x75\x25\x98"
    ; "\x11\x00\x00"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string input ~off:0 ~len:(String.length input) in
  match Lzo.uncompress_with_buffer input with
  | Ok str ->
    Alcotest.(check string) "output" str (String.concat "" output_lzo_5)
  | Error _ -> Alcotest.failf "Invalid LZO input"

let test_lzo_6 () =
  Alcotest.test_case "invalid returns error" `Quick @@ fun () ->
  let input =
    [
      "\xa4\xc2\xef\xc2\x90\x53\x83\xda\xfc\xd2\x1d\xed\x32\xe0\x63\x52"
    ; "\xe1\x72\x2c\x1c\xf3\x9f\x8b\x6d\x04\x12\xfe\x98\x10\xcf\xb0\x3e"
    ; "\xc2\x0d\xf5\x23\xbd\x80\x0a\xb3\x5d\x07\xfb\xa2\x4f\xf7\x86\xa5"
    ; "\x35\xad\x06\x13\xd8\x18\x57\xb6\xdb\xf5\x75\x91\x25\x4f\x1a\xc1"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string ~off:0 ~len:(String.length input) input in
  match Lzo.uncompress_with_buffer input with
  | Ok _ -> Alcotest.failf "Unexpected valid LZO input"
  | Error _ -> Alcotest.(check pass) "input errored" () ()

(* TODO(dinosaure): this test does not work! *)
let test_lzo_7 () =
  Alcotest.test_case "afl: input EOF without End_of_stream marker returns Error"
    `Quick
  @@ fun () ->
  let input =
    [
      "\x4b\xf8\xfb\x57\xfd\x99\xc3\x23\x3d\xd6\xec\x8b\xd1\x30\xc6\x9a"
    ; "\xcd\x4f\xea\x13\xc7\x90\xcb\xd1\xa2\xf9\xd2\x14\x82\x81\xab\xe1"
    ; "\x3b\xdd\x5d\xef\xfa\x90\xc0\xdb\xee\x7b\x31\xcf\xcf\x72\xdf\xc8"
    ; "\x19\xa5\x5f\x04\xcd\x21\x91\xf7\xd9\xb2\x6c\x66\x07\x7d\x02\x75"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string ~off:0 ~len:(String.length input) input in
  match Lzo.uncompress_with_buffer input with
  | Ok _ -> Alcotest.failf "Unexpected valid LZO input"
  | Error _ -> Alcotest.(check pass) "input errored" () ()

let test_lzo_8 () =
  Alcotest.test_case "afl: invalid returns error" `Quick @@ fun () ->
  let input =
    [
      "\xa4\xc2\xef\xc2\x90\x53\x83\xda\xfc\xd2\x1d\xed\x32\xe0\x63\x52"
    ; "\xe1\x72\x2c\x1c\xf3\x9f\x8b\x6d\x04\x12\xfe\x98\x10\xcf\xb0\x3e"
    ; "\xc2\x0d\xf5\x23\xbd\x80\x0a\xb3\x5d\x07\xfb\xa2\x4f\xf7\x86\xa5"
    ; "\x35\xad\x06\x13\xd8\x18\x57\xb6\xdb\xf5\x75\x91\x25\x4f\x1a\xc1"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string ~off:0 ~len:(String.length input) input in
  match Lzo.uncompress_with_buffer input with
  | Ok _ -> Alcotest.failf "Unexpected valid LZO input"
  | Error _ -> Alcotest.(check pass) "input errored" () ()

let test_lzo_9 () =
  Alcotest.test_case "short literals" `Quick @@ fun () ->
  let error =
    let pp ppf = function
      | `Malformed err -> Fmt.pf ppf "malformed: %s" err
      | `Invalid_argument err -> Fmt.pf ppf "invalid argument: %s" err
      | `Invalid_dictionary -> Fmt.string ppf "invalid dictionary" in
    Alcotest.testable pp ( = ) in
  let uncompress str =
    let input = Bigstringaf.of_string ~off:0 ~len:(String.length str) str in
    Lzo.uncompress_with_buffer input in
  let res = Alcotest.(result string error) in
  Alcotest.(check res) "is empty" (Ok "") (uncompress "\x11\x00\x00")
  ; Alcotest.(check res)
      "is 0x31" (Ok "\x31")
      (uncompress "\x12\x31\x11\x00\x00")
  ; Alcotest.(check res)
      "is 0x31 0x32" (Ok "\x31\x32")
      (uncompress "\x13\x31\x32\x11\x00\x00")
  ; Alcotest.(check res)
      "is A B C" (Ok "ABC")
      (uncompress "\x14ABC\x11\x00\x00")
  ; Alcotest.(check res)
      "is A B C D" (Ok "ABCD")
      (uncompress "\x15ABCD\x11\x00\x00")
  ; Alcotest.(check res)
      "is A B C D E" (Ok "ABCDE")
      (uncompress "\x16ABCDE\x11\x00\x00")
  ; Alcotest.(check res)
      "is A B C D E F" (Ok "ABCDEF")
      (uncompress "\x17ABCDEF\x11\x00\x00")
  ; Alcotest.(check res)
      "is A B C D E F G" (Ok "ABCDEFG")
      (uncompress "\x18ABCDEFG\x11\x00\x00")
  ; let input =
      [
        "\x30\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31"
      ; "\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31"
      ; "\x11\x00\x00"
      ] in
    Alcotest.(check res)
      "is a lot of 1s" (Ok "1111111111111111111111111111111")
      (uncompress (String.concat "" input))

let test_lzo_10 () =
  Alcotest.test_case "againandagain" `Quick @@ fun () ->
  let input =
    [
      "\x00\x24\x54\x68\x65\x20\x71\x75\x69\x63\x6b\x20\x62\x72\x6f\x77"
    ; "\x6e\x20\x66\x6f\x78\x20\x6a\x75\x6d\x70\x65\x64\x20\x6f\x76\x65"
    ; "\x72\x20\x74\x68\x65\x20\x6c\x61\x7a\x79\x20\x64\x6f\x67\x2e\x20"
    ; "\x61\x67\x61\x69\x6e\x61\x6e\x64\x32\x1c\x00\x0f\x6e\x61\x6e\x64"
    ; "\x61\x67\x61\x69\x6e\x61\x6e\x64\x61\x67\x61\x69\x6e\x2e\x11\x00"; "\x00"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string ~off:0 ~len:(String.length input) input in
  let output =
    "The quick brown fox jumped over the lazy dog. \
     againandagainandagainandagainandagainandagain." in
  match Lzo.uncompress_with_buffer input with
  | Ok output' -> Alcotest.(check string) "againandagain" output output'
  | Error _ -> Alcotest.failf "Invalid LZO input"

let test_lzo_11 () =
  Alcotest.test_case "yooyooyoo" `Quick @@ fun () ->
  let input =
    "\x20\x79\x6f\x6f\x79\x6f\x6f\x79\x6f\x6f\x79\x6f\x6f\x79\x6f\x6f\x11\x00\x00"
  in
  let input = Bigstringaf.of_string ~off:0 ~len:(String.length input) input in
  match Lzo.uncompress_with_buffer input with
  | Ok str -> Alcotest.(check string) "yooyooyoo" str "yooyooyooyooyoo"
  | Error _ -> Alcotest.failf "Invalid LZO input"

let test_lzo_12 () =
  Alcotest.test_case "random short" `Quick @@ fun () ->
  let error =
    let pp ppf = function
      | `Malformed err -> Fmt.pf ppf "malformed: %s" err
      | `Invalid_argument err -> Fmt.pf ppf "invalid argument: %s" err
      | `Invalid_dictionary -> Fmt.string ppf "invalid dictionary" in
    Alcotest.testable pp ( = ) in
  let uncompress str =
    let input = Bigstringaf.of_string ~off:0 ~len:(String.length str) str in
    Lzo.uncompress_with_buffer input in
  let res = Alcotest.(result string error) in
  Alcotest.(check res)
    "01" (Ok "\xb1\x72\xc0\x91\xbc")
    (uncompress "\x16\xb1\x72\xc0\x91\xbc\x11\x00\x00")
  ; Alcotest.(check res)
      "02" (Ok "\x07\x75\x3a\x02\xce\xfc\x86\x42\xd3\x14")
      (uncompress "\x1b\x07\x75\x3a\x02\xce\xfc\x86\x42\xd3\x14\x11\x00\x00")
  ; let input =
      [
        "\x6e\x31\x43\x6e\xd7\x73\xb7\xa4\x5f\x79\xe2\x26\xab\x60\x38\x38"
      ; "\x0e\x1a\x59\x24\xf2\xaf\xa4\x2e\x6f\xa5\xa5\x8f\x80\x1a\x06\xe7"
      ] in
    let output =
      [
        "\x31\x6e\x31\x43\x6e\xd7\x73\xb7\xa4\x5f\x79\xe2\x26\xab\x60\x38"
      ; "\x38\x0e\x1a\x59\x24\xf2\xaf\xa4\x2e\x6f\xa5\xa5\x8f\x80\x1a\x06"
      ; "\xe7\x11\x00\x00"
      ] in
    Alcotest.(check res)
      "03"
      (Ok (String.concat "" input))
      (uncompress (String.concat "" output))
    ; let input =
        [
          "\x20\xb2\x02\x43\x4b\x12\x59\x3c\x22\xce\xe6\x32\xbd\xe7\xff\x9f"
        ; "\xf1\x2a\xab\x5e\x5d\x26\xe9\x4d\x94\xa7\x73\x91\x4c\x60\x7d\x8a"
        ; "\x2e\x17\x42\xb2\x89\x6a\xbf\x1f\xe7\xa9\x9c\xe2\xf8\x8a\x36\xa9"
        ; "\xc6\xf2\x60\xa1\x2d\x20\xf0\xba\x9a\x4a\xb3\x60\x57\x52\x8a\x55"
        ; "\x40\x24\x7c\x84\x7c\x72\x1a\x5e\xbc\x2c\x80\x85\xf7\x22\x28\xc0"
        ; "\x1a\xa6\x1d\x8c\xc3\x53\x46\x04\x3e\x8b\x75\xcc\x1f\x8f\xab\x8f"
        ; "\x4b\x7b\x4e\xfb\x11\xa3\xb2\xfb\x60\x75\x3e\x83\x5a\x9d\x46\x2d"
        ; "\x16\xc5\x7c\x2f\xa2\xfe\x42\x2f\x1c\xb1\x06\x22\x8f\xd0\x99\xb9"
        ] in
      let output =
        [
          "\x91\x20\xb2\x02\x43\x4b\x12\x59\x3c\x22\xce\xe6\x32\xbd\xe7\xff"
        ; "\x9f\xf1\x2a\xab\x5e\x5d\x26\xe9\x4d\x94\xa7\x73\x91\x4c\x60\x7d"
        ; "\x8a\x2e\x17\x42\xb2\x89\x6a\xbf\x1f\xe7\xa9\x9c\xe2\xf8\x8a\x36"
        ; "\xa9\xc6\xf2\x60\xa1\x2d\x20\xf0\xba\x9a\x4a\xb3\x60\x57\x52\x8a"
        ; "\x55\x40\x24\x7c\x84\x7c\x72\x1a\x5e\xbc\x2c\x80\x85\xf7\x22\x28"
        ; "\xc0\x1a\xa6\x1d\x8c\xc3\x53\x46\x04\x3e\x8b\x75\xcc\x1f\x8f\xab"
        ; "\x8f\x4b\x7b\x4e\xfb\x11\xa3\xb2\xfb\x60\x75\x3e\x83\x5a\x9d\x46"
        ; "\x2d\x16\xc5\x7c\x2f\xa2\xfe\x42\x2f\x1c\xb1\x06\x22\x8f\xd0\x99"
        ; "\xb9\x11\x00\x00"
        ] in
      Alcotest.(check res)
        "04"
        (Ok (String.concat "" input))
        (uncompress (String.concat "" output))
      ; let input =
          [
            "\x8a\x6c\xac\xf2\x4c\x02\xbe\x6d\x4d\x6b\x12\xa6\x68\x14\xaf\x9d"
          ; "\xeb\xb0\xc7\x5d\xd8\xb5\x28\x1c\x8e\x32\x66\x89\xef\x81\x03\xdb"
          ; "\xf8\x8b\x01\x49\xa5\x31\x92\xf1\xe8\x9a\xe7\xda\xe2\x1d\x0a\x96"
          ; "\xd3\x92\xa3\x7b\x68\xb8\x82\x54\x91\x5f\xec\x6e\xd4\x51\x30\xce"
          ; "\x1c\xbf\xbd\x3f\x3f\xb9\x23\x85\x8d\xdd\x17\xa0\x77\xab\x79\x53"
          ; "\xef\xe4\xd5\x17\xad\x83\x1d\x93\xa3\x23\x40\x3a\xdb\x0d\xc7\xc6"
          ; "\x27\x48\x2d\x3f\xdf\xbb\x0c\x94\x68\x47\x66\xba\x6a\x9b\x46\xfc"
          ; "\x1d\xb5\xe2\xc9\xa8\x07\x55\xe1\xc4\xaa\x9c\x1c\xab\x00\xcd\x95"
          ; "\x1d\xbf\x2b\x8f\xe3\x6b\x1c\x53\xd1\x69\x3a\xd8\x24\x8b\x96\x88"
          ; "\x71\x6c\x65\x21\x45\x3e\xf3\xc5\xa8\x8f\x3b\xd7\x7b\xc2\xf2\x9d"
          ; "\xa5\xbe\x30\x55\x03\xb7\x16\xeb\xf8\xa3\x05\x31\x6a\x84\x19\x7c"
          ; "\x08\x84\x6a\x8c\xe0\x95\x95\x6f\xbf\x44\x4d\x38\x2a\x47\x92\xf8"
          ; "\xcf\x3c\x97\xca\x4f\xd1\x81\x73\x69\xce\xde\x38\xe3\x55\x03\x1d"
          ; "\xfd\x13\x39\x07\xbd\x83\xb7\x75\x39\xe3\x0d\xd2\x42\x46\x46\xfc"
          ; "\x89\xd1\x21\xcb\x94\xde\xb7\xb3\x10\x21\xff\xaa\x19\xea\x2b\x45"
          ; "\xd0\xba\x77\xb2\xfd\x13\x62\x82\x55\xa9\xb3\xcb\xdb\x06\xf3\x40"
          ] in
        let output =
          [
            "\x00\xee\x8a\x6c\xac\xf2\x4c\x02\xbe\x6d\x4d\x6b\x12\xa6\x68\x14"
          ; "\xaf\x9d\xeb\xb0\xc7\x5d\xd8\xb5\x28\x1c\x8e\x32\x66\x89\xef\x81"
          ; "\x03\xdb\xf8\x8b\x01\x49\xa5\x31\x92\xf1\xe8\x9a\xe7\xda\xe2\x1d"
          ; "\x0a\x96\xd3\x92\xa3\x7b\x68\xb8\x82\x54\x91\x5f\xec\x6e\xd4\x51"
          ; "\x30\xce\x1c\xbf\xbd\x3f\x3f\xb9\x23\x85\x8d\xdd\x17\xa0\x77\xab"
          ; "\x79\x53\xef\xe4\xd5\x17\xad\x83\x1d\x93\xa3\x23\x40\x3a\xdb\x0d"
          ; "\xc7\xc6\x27\x48\x2d\x3f\xdf\xbb\x0c\x94\x68\x47\x66\xba\x6a\x9b"
          ; "\x46\xfc\x1d\xb5\xe2\xc9\xa8\x07\x55\xe1\xc4\xaa\x9c\x1c\xab\x00"
          ; "\xcd\x95\x1d\xbf\x2b\x8f\xe3\x6b\x1c\x53\xd1\x69\x3a\xd8\x24\x8b"
          ; "\x96\x88\x71\x6c\x65\x21\x45\x3e\xf3\xc5\xa8\x8f\x3b\xd7\x7b\xc2"
          ; "\xf2\x9d\xa5\xbe\x30\x55\x03\xb7\x16\xeb\xf8\xa3\x05\x31\x6a\x84"
          ; "\x19\x7c\x08\x84\x6a\x8c\xe0\x95\x95\x6f\xbf\x44\x4d\x38\x2a\x47"
          ; "\x92\xf8\xcf\x3c\x97\xca\x4f\xd1\x81\x73\x69\xce\xde\x38\xe3\x55"
          ; "\x03\x1d\xfd\x13\x39\x07\xbd\x83\xb7\x75\x39\xe3\x0d\xd2\x42\x46"
          ; "\x46\xfc\x89\xd1\x21\xcb\x94\xde\xb7\xb3\x10\x21\xff\xaa\x19\xea"
          ; "\x2b\x45\xd0\xba\x77\xb2\xfd\x13\x62\x82\x55\xa9\xb3\xcb\xdb\x06"
          ; "\xf3\x40\x11\x00\x00"
          ] in
        Alcotest.(check res)
          "05"
          (Ok (String.concat "" input))
          (uncompress (String.concat "" output))

let test_lzo_13 () =
  Alcotest.test_case "literal after literal" `Quick @@ fun () ->
  let input =
    [
      "\x01\x61\x62\x63\x64\x42\x00\x41\x42\x00\x00\x02\x30\x31\x32\x33"
    ; "\x34\x11\x00\x00"
    ] in
  let input = String.concat "" input in
  let input = Bigstringaf.of_string ~off:0 ~len:(String.length input) input in
  match Lzo.uncompress_with_buffer input with
  | Ok str ->
    Alcotest.(check string) "lieral after literal" str "abcddddABBB01234"
  | Error _ -> Alcotest.failf "Invalid LZO input"

let test_lzo_14 () =
  Alcotest.test_case "shorts" `Quick @@ fun () ->
  let error =
    let pp ppf = function
      | `Malformed err -> Fmt.pf ppf "malformed: %s" err
      | `Invalid_argument err -> Fmt.pf ppf "invalid argument: %s" err
      | `Invalid_dictionary -> Fmt.string ppf "invalid dictionary" in
    Alcotest.testable pp ( = ) in
  let uncompress str =
    let input = Bigstringaf.of_string ~off:0 ~len:(String.length str) str in
    Lzo.uncompress_with_buffer input in
  let res = Alcotest.(result string error) in
  let input =
    [
      "\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31"
    ; "\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x31\x32"
    ] in
  let output =
    [
      "\x02\x31\x31\x31\x31\x31\x2a\x10\x00\x0c\x31\x31\x31\x31\x31\x31"
    ; "\x31\x31\x31\x31\x31\x31\x31\x31\x32\x11\x00\x00"
    ] in
  Alcotest.(check res)
    "01"
    (Ok (String.concat "" input))
    (uncompress (String.concat "" output))
  ; let input =
      [
        "\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30"
      ; "\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30"
      ; "\x30"
      ] in
    let output =
      [
        "\x02\x30\x30\x30\x30\x30\x2a\x10\x00\x0d\x30\x30\x30\x30\x30\x30"
      ; "\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x11\x00\x00"
      ] in
    Alcotest.(check res)
      "02"
      (Ok (String.concat "" input))
      (uncompress (String.concat "" output))

let test_lzo_15 () =
  Alcotest.test_case "CVE 2017 8845" `Quick @@ fun () ->
  let error =
    let pp ppf = function
      | `Malformed err -> Fmt.pf ppf "malformed: %s" err
      | `Invalid_argument err -> Fmt.pf ppf "invalid argument: %s" err
      | `Invalid_dictionary -> Fmt.string ppf "invalid dictionary" in
    Alcotest.testable pp ( = ) in
  let uncompress str =
    let input = Bigstringaf.of_string ~off:0 ~len:(String.length str) str in
    Lzo.uncompress_with_buffer input in
  let res = Alcotest.(result string error) in
  let many_As = String.make (3 + 15 + 176) 'A' in
  Alcotest.(check res)
    "literal run of 3+15+382 bytes, overflows (2**7)-1" (Ok many_As)
    (uncompress ("\000\xb0" ^ many_As ^ "\x11\x00\x00"))
  ; let many_As = String.make (3 + 15 + 382) 'A' in
    Alcotest.(check res)
      "literal run of 3+15+382 bytes, overflows (2**8)-1" (Ok many_As)
      (uncompress ("\x00\x00\x7f" ^ many_As ^ "\x11\x00\x00"))
    ; let many_As = String.make (3 + 15 + 33151) 'A' in
      Alcotest.(check res)
        "literal run of 3+15+33151 bytes, overflows (2**15)-1" (Ok many_As)
        (uncompress
           ("\x00" ^ String.make 130 '\x00' ^ "\x01" ^ many_As ^ "\x11\x00\x00"))
      ; let many_As = String.make (3 + 15 + 76501) 'A' in
        let output =
          "\x00" ^ String.make 300 '\x00' ^ "\x01" ^ many_As ^ "\x11\x00\x00"
        in
        Alcotest.(check res)
          "literal run of 3+15+76501 bytes, overflows (2**16)-1" (Ok many_As)
          (uncompress output)
        ; Alcotest.(check res)
            "literal run of 1073742016 bytes, overflows (2**30)-1"
            (Error (`Malformed "Malformed input"))
            (uncompress
               ("\x00" ^ String.make 4210753 '\x00' ^ "\x01\x11\x00\x00"))
        ; Alcotest.(check res)
            "literal run of 2147483776 bytes, overflows (2**31)-1"
            (Error (`Malformed "Malformed input"))
            (uncompress
               ("\x00" ^ String.make 8421505 '\x00' ^ "\x01\x11\x00\x00"))
        ; if Sys.word_size > 32 then
            Alcotest.(check res)
              "literal run of 429529776 bytes, overflows (2**31)-1"
              (Error (`Malformed "Malformed input"))
              (uncompress
                 ("\x00" ^ String.make 16844305 '\x00' ^ "\x01\x11\x00\x00"))

let test_minilzo () =
  Alcotest.test_case "minilzo" `Quick @@ fun () -> Minilzo.minilzo ()

let () =
  Alcotest.run "lzo"
    [
      ( "lzo"
      , [
          test_lzo_0 (); test_lzo_1 (); test_lzo_2 (); test_lzo_3 ()
        ; test_lzo_4 (); test_lzo_5 (); test_lzo_6 () ; test_lzo_7 ()
        ; test_lzo_8 (); test_lzo_9 (); test_lzo_10 (); test_lzo_11 ()
        ; test_lzo_12 (); test_lzo_13 (); test_lzo_14 (); test_lzo_15 ()
        ] ); "minilzo", [test_minilzo ()]
    ]
