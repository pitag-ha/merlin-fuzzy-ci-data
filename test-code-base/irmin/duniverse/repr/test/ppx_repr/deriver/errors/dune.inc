(env
 (_
  (env-vars
   (OCAML_ERROR_STYLE "short")
   (OCAML_COLOR "never"))))

; -------- Test: `lib_invalid.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets lib_invalid.actual)
 (deps
  (:pp pp.exe)
  (:input lib_invalid.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff lib_invalid.expected lib_invalid.actual)))

; -------- Test: `nobuiltin_nonempty.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets nobuiltin_nonempty.actual)
 (deps
  (:pp pp.exe)
  (:input nobuiltin_nonempty.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff nobuiltin_nonempty.expected nobuiltin_nonempty.actual)))

; -------- Test: `recursion_more_than_two.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets recursion_more_than_two.actual)
 (deps
  (:pp pp.exe)
  (:input recursion_more_than_two.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (enabled_if (>= %{ocaml_version} 4.09))
 (package ppx_repr)
 (action
  (diff recursion_more_than_two.expected recursion_more_than_two.actual)))

; -------- Test: `recursion_with_type_parameters.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets recursion_with_type_parameters.actual)
 (deps
  (:pp pp.exe)
  (:input recursion_with_type_parameters.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (enabled_if (>= %{ocaml_version} 4.09))
 (package ppx_repr)
 (action
  (diff recursion_with_type_parameters.expected
    recursion_with_type_parameters.actual)))

; -------- Test: `unsupported_polyvar_inherit_case.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_polyvar_inherit_case.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_polyvar_inherit_case.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_polyvar_inherit_case.expected
    unsupported_polyvar_inherit_case.actual)))

; -------- Test: `unsupported_tuple_size.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_tuple_size.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_tuple_size.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_tuple_size.expected unsupported_tuple_size.actual)))

; -------- Test: `unsupported_type_arrow.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_type_arrow.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_type_arrow.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_type_arrow.expected unsupported_type_arrow.actual)))

; -------- Test: `unsupported_type_extension.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_type_extension.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_type_extension.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_type_extension.expected unsupported_type_extension.actual)))

; -------- Test: `unsupported_type_open.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_type_open.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_type_open.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_type_open.expected unsupported_type_open.actual)))

; -------- Test: `unsupported_type_open_polyvariant.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_type_open_polyvariant.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_type_open_polyvariant.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_type_open_polyvariant.expected
    unsupported_type_open_polyvariant.actual)))

; -------- Test: `unsupported_type_package.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_type_package.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_type_package.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_type_package.expected unsupported_type_package.actual)))

; -------- Test: `unsupported_type_poly.ml` --------



; Run the PPX on the `.ml` file
(rule
 (targets unsupported_type_poly.actual)
 (deps
  (:pp pp.exe)
  (:input unsupported_type_poly.ml))
 (action
  ; expect the process to fail, capturing stderr
  (with-stderr-to
   %{targets}
   (bash "! ./%{pp} -no-color --impl %{input}"))))

; Compare the post-processed output to the .expected file
(rule
 (alias runtest)
 (package ppx_repr)
 (action
  (diff unsupported_type_poly.expected unsupported_type_poly.actual)))


