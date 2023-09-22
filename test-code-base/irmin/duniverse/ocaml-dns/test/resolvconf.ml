
let ok =
  let module M = struct
    type t = [ `Nameserver of Ipaddr.t ] list
    let pp =
      let pp_one ppf = function
        | `Nameserver ip -> Fmt.pf ppf "nameserver %a" Ipaddr.pp ip
      in
      Fmt.(list ~sep:(any "\n") pp_one)
    let equal a b = compare a b = 0 (* TODO polymorphic equality *)
  end in
  (module M: Alcotest.TESTABLE with type t = M.t)

let err =
  let module M = struct
    type t = [ `Msg of string ]
    let pp ppf = function
      | `Msg m -> Fmt.string ppf m
    let equal _ _ = true
  end in
  (module M: Alcotest.TESTABLE with type t = M.t)

let test_one test_name (data, expected) () =
  Alcotest.(check (result ok err)
              ("resolvconf " ^ test_name) expected (Dns_resolvconf.parse data))

let v4_ns = [ "8.8.8.8" ; "8.8.4.4" ]

and v6_ns = [ "2001:4860:4860::8888" ; "2001:4860:4860::8844" ]

let ok_result ns =
  Ok (List.map (fun s -> `Nameserver (Ipaddr.of_string_exn s)) ns)

let linux =
  {|
# Not all of these are supported by TRust-DNS
# They are testing that they don't break parsing
options ndots:8 timeout:8 attempts:8

domain example.com
search example.com sub.example.com

nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
nameserver 8.8.8.8
nameserver 8.8.4.4

# some options not supported by TRust-DNS
options rotate
options inet6 no-tld-query

# A basic option not supported
sortlist 130.155.160.0/255.255.240.0 130.155.0.0
|}

let macos =
  {|
#
# Mac OS X Notice
#
# This file is not used by the host name and address resolution
# or the DNS query routing mechanisms used by most processes on
# this Mac OS X system.
#
# This file is automatically generated.
#
options ndots:8 timeout:8 attempts:8
domain example.com.
search example.com. sub.example.com.
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
nameserver 8.8.8.8
nameserver 8.8.4.4
|}

let openbsd =
  {|
# Generated by em0 dhclient
nameserver 8.8.8.8
nameserver 8.8.4.4
lookup file bind
|}

let simple =
  {|
nameserver 8.8.8.8
nameserver 8.8.4.4
|}

let nixos =
  {|
nameserver fe80::c2d7:aaff:fe96:8d82%wlp3s0
|}

let nixos2 =
  {|
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver fe80::c2d7:aaff:fe96:8d82%wlp3s0
nameserver 8.8.8.8
nameserver 8.8.4.4
|}

let local_ns = [ "fe80::c2d7:aaff:fe96:8d82" ]

let tests = [
  "linux", `Quick, test_one "linux" (linux, ok_result (v6_ns @ v4_ns)) ;
  "macos", `Quick, test_one "macos" (macos, ok_result (v6_ns @ v4_ns)) ;
  "openbsd", `Quick, test_one "openbsd" (openbsd, ok_result v4_ns) ;
  "simple", `Quick, test_one "simple" (simple, ok_result v4_ns) ;
  "nixos", `Quick, test_one "nixos (with zone index)"
    (nixos, ok_result local_ns) ;
  "nixos 2", `Quick, test_one "nixos 2 (with zone index)"
    (nixos2, ok_result (v4_ns @ local_ns @ v4_ns)) ;
]

let () = Alcotest.run "DNS resolvconf tests" [ "resolvconf tests", tests ]

