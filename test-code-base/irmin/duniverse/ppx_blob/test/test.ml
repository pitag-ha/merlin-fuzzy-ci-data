let suite = [
  ("path relative to source file", `Quick, fun () ->
    Alcotest.(check string) "file contents" "foo\n" [%blob "test_file"]
  );
]

let () =
  Alcotest.run "ppx_blob" [
    "basic", suite
  ]
