let examples =
  Examples.
    [ ( "bar_styles"
      , "Demo of possible progress bar configurations"
      , Bar_styles.run )
    ; ("cargo", "Port of the Cargo install progress bar", Cargo.run)
    ; ("download", "Rainbow-coloured download sequence", Download.run)
    ; ("interject", "Logging while displaying a progress bar", Interject.run)
    ; ("readme", "Demonstration included in the README", Readme.run)
    ; ("spinners", "Demo of possible spinner configurations", Spinners.run)
    ; ("yarn", "Yarn-like download and install sequence", Yarn.run)
    ]

let available_examples () =
  Format.eprintf "Available examples: @.";
  ListLabels.iter examples ~f:(fun (name, desc, _) ->
      Format.eprintf "- %-12s %a@." name
        Fmt.(styled `Faint (parens string))
        desc)

let usage () =
  Format.eprintf "@.";
  available_examples ();
  Format.eprintf "\n%a: dune exec %s%s%s.exe -- [--help] <example_name>@."
    Fmt.(styled `Green string)
    "usage" Filename.current_dir_name Filename.dir_sep
    (Filename.chop_extension __FILE__)

let () =
  Random.self_init ();
  Fmt.set_style_renderer Fmt.stderr `Ansi_tty;
  match Sys.argv with
  | [| _ |] | [| _; "-h" | "-help" | "--help" |] -> usage ()
  | [| _; "--list" |] ->
      ListLabels.iter ~f:(fun (name, _, _) -> print_endline name) examples
  | [| _; name |] -> (
      match
        List.find_opt
          (fun (n, _, _) -> n = String.lowercase_ascii name)
          examples
      with
      | None ->
          Format.eprintf "%a: unrecognised example name `%a`.@.@."
            Fmt.(styled `Bold @@ styled `Red string)
            "Error"
            Fmt.(styled `Cyan string)
            name;
          available_examples ();
          exit 1
      | Some (_, _, f) -> f ())
  | _ ->
      usage ();
      exit 1
