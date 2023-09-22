open Rresult
open Lwt.Infix

let ( <.> ) f g = fun x -> f (g x)
let always x = fun _ -> x

module Make
  (Random : Mirage_random.S)
  (Certificate : Mirage_kv.RO)
  (Key : Mirage_kv.RO)
  (Tcp : Tcpip.Tcp.S with type ipaddr = Ipaddr.t)
  (Connect : Connect.S)
  (HTTP_Server : Paf_mirage.S) = struct

  let tls key_ro certificate_ro =
    let open Lwt_result.Infix in
    Lwt.Infix.(Key.list key_ro Mirage_kv.Key.empty
    >|= R.reword_error (R.msgf "%a" Key.pp_error)) >>= fun keys ->
    let keys, _ = List.partition (fun (_, t) -> t = `Value) keys in
    Lwt.Infix.(Certificate.list certificate_ro Mirage_kv.Key.empty
    >|= R.reword_error (R.msgf "%a" Certificate.pp_error)) >>= fun certificates ->
    let certificates, _ = List.partition (fun (_, t) -> t = `Value) certificates in
    let fold acc (name, _) = match name with
      | ".gitkeep" -> Lwt.return acc
      | _ ->
        let open Lwt_result.Infix in
        Lwt.Infix.(Certificate.get certificate_ro
          Mirage_kv.Key.(empty / name) >|= R.reword_error (R.msgf "%a" Certificate.pp_error))
        >|= Cstruct.of_string
        >>= (Lwt.return <.> X509.Certificate.decode_pem_multiple)
        >>= fun certificates -> Lwt.return acc >>= fun acc ->
        Lwt.return_ok ((name, certificates) :: acc) in
    Lwt_list.fold_left_s fold (Ok []) certificates >>= fun certificates ->
    let fold acc (name, _) = match name with
      | ".gitkeep" -> Lwt.return acc
      | _ ->
        let open Lwt_result.Infix in
        Lwt.Infix.(Key.get key_ro 
          Mirage_kv.Key.(empty / name) >|= R.reword_error (R.msgf "%a" Key.pp_error))
        >|= Cstruct.of_string
        >>= (Lwt.return <.> X509.Private_key.decode_pem)
        >>= fun key -> Lwt.return acc
        >>= fun acc -> Lwt.return_ok ((name, key) :: acc) in
    Lwt_list.fold_left_s fold (Ok []) keys >>= fun keys ->
    let tbl = Hashtbl.create 0x10 in
    List.iter (fun (name, certificates) -> match List.assoc_opt name keys with
      | Some key -> Hashtbl.add tbl name (certificates, key)
      | None -> ()) certificates ;
    match Hashtbl.fold (fun _ certchain acc -> certchain :: acc) tbl [] with
    | [] -> Lwt.return_ok `None
    | [ certchain ] -> Lwt.return_ok (`Single certchain)
    | certchains -> Lwt.return_ok (`Multiple certchains)

  let http_1_1_request_handler ~ctx ~authenticator flow _edn =
    let module R = (val (Mimic.repr HTTP_Server.tcp_protocol)) in
    fun reqd ->
      match (Httpaf.Reqd.request reqd).Httpaf.Request.meth with
      | `CONNECT ->
        HTTP_Server.TCP.no_close flow ;
        let to_close = function
          | R.T flow -> HTTP_Server.TCP.to_close flow
          | _ -> () in
        Server.http_1_1_request_handler ~ctx ~authenticator ~to_close (R.T flow) reqd
      | _ ->
        Server.http_1_1_request_handler ~ctx ~authenticator ~to_close:(always ()) (R.T flow) reqd

  let alpn_handler ~ctx ~authenticator =
    let module R = (val (Mimic.repr HTTP_Server.tls_protocol)) in
    let to_close = function
      | R.T flow -> HTTP_Server.TLS.to_close flow
      | _ -> () in
    { Alpn.error= Server.alpn_error_handler
    ; Alpn.request= (fun flow edn reqd protocol ->
      Server.alpn_request_handler ~ctx ~authenticator ~to_close (R.T flow) edn reqd protocol) }

  let run_with_tls ~ctx ~authenticator ~tls tcpv4v6 http_server =
    let alpn_service = HTTP_Server.alpn_service ~tls (alpn_handler ~ctx ~authenticator) in
    let http_1_1_service =
      HTTP_Server.http_service ~error_handler:Server.http_1_1_error_handler
        (http_1_1_request_handler ~ctx ~authenticator) in
    HTTP_Server.init ~port:(Key_gen.tls_port ()) tcpv4v6 >>= fun tls_server ->
    let `Initialized th0 = HTTP_Server.serve alpn_service tls_server in
    let `Initialized th1 = HTTP_Server.serve http_1_1_service http_server in
    Lwt.both th0 th1 >>= fun ((), ()) -> Lwt.return_unit

  let run ~ctx ~authenticator http_server =
    let http_1_1_service =
      HTTP_Server.http_service ~error_handler:Server.http_1_1_error_handler
        (http_1_1_request_handler ~ctx ~authenticator) in
    let `Initialized th = HTTP_Server.serve http_1_1_service http_server in th

  let start _random certificate_ro key_ro tcpv4v6 ctx http_server =
    let open Lwt.Infix in
    let authenticator = Connect.authenticator in
    tls key_ro certificate_ro >>= fun tls ->
    match Key_gen.tls (), tls, Key_gen.alpn () with
    | true, Ok certificates, None ->
      run_with_tls ~ctx ~authenticator ~tls:(Tls.Config.server ~certificates ~alpn_protocols:[ "h2"; "http/1.1" ] ())
        tcpv4v6 http_server
    | true, Ok certificates, Some (("http/1.1" | "h2") as alpn_protocol) ->
      run_with_tls ~ctx ~authenticator ~tls:(Tls.Config.server ~certificates ~alpn_protocols:[ alpn_protocol ] ())
        tcpv4v6 http_server
    | false, _, _ -> run ~ctx ~authenticator http_server
    | _, _, Some protocol -> Fmt.failwith "Invalid protocol %S" protocol
    | true, Error _, _ -> Fmt.failwith "A TLS server requires, at least, one certificate and one private key."
end
