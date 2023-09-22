(** Module test for ppx_deriving_qcheck *)
open Ppxlib

(** Primitive types tests *)
let loc = Location.none

let f = Ppx_deriving_qcheck.derive_gens ~version:`QCheck2 ~loc

let f' xs = List.map f xs |> List.concat

let extract stri =
  match stri.pstr_desc with Pstr_type (x, y) -> (x, y) | _ -> assert false

let extract' xs = List.map extract xs

let check_eq ~expected ~actual name =
  let f = Ppxlib.Pprintast.string_of_structure in
  Alcotest.(check string) name (f expected) (f actual)

let test_int () =
  let expected = [ [%stri let gen = QCheck2.Gen.int] ] in

  let actual = f @@ extract [%stri type t = int] in

  check_eq ~expected ~actual "deriving int"

let test_float () =
  let expected = [ [%stri let gen = QCheck2.Gen.float] ] in
  let actual = f @@ extract [%stri type t = float] in

  check_eq ~expected ~actual "deriving float"

let test_char () =
  let expected = [ [%stri let gen = QCheck2.Gen.char] ] in
  let actual = f @@ extract [%stri type t = char] in

  check_eq ~expected ~actual "deriving char"

let test_string () =
  let expected = [ [%stri let gen = QCheck2.Gen.string] ] in
  let actual = f @@ extract [%stri type t = string] in

  check_eq ~expected ~actual "deriving string"

let test_unit () =
  let expected = [ [%stri let gen = QCheck2.Gen.unit] ] in
  let actual = f @@ extract [%stri type t = unit] in

  check_eq ~expected ~actual "deriving unit"

let test_bool () =
  let expected = [ [%stri let gen = QCheck2.Gen.bool] ] in
  let actual = f @@ extract [%stri type t = bool] in

  check_eq ~expected ~actual "deriving bool"

let test_int32 () =
  let expected = [ [%stri let gen = QCheck2.Gen.ui32] ] in
  let actual = f @@ extract [%stri type t = int32] in

  check_eq ~expected ~actual "deriving int32"

let test_int32' () =
  let expected = [ [%stri let gen = QCheck2.Gen.ui32] ] in
  let actual = f @@ extract [%stri type t = Int32.t] in

  check_eq ~expected ~actual "deriving int32'"

let test_int64 () =
  let expected = [ [%stri let gen = QCheck2.Gen.ui64] ] in
  let actual = f @@ extract [%stri type t = int64] in

  check_eq ~expected ~actual "deriving int64"

let test_int64' () =
  let expected = [ [%stri let gen = QCheck2.Gen.ui64] ] in
  let actual = f @@ extract [%stri type t = Int64.t] in

  check_eq ~expected ~actual "deriving int64'"

(* let test_bytes () =
 *   let expected =
 *     [
 *       [%stri
 *         let gen =
 *           QCheck2.map
 *             (fun n -> Bytes.create n)
 *             QCheck2.(0 -- Sys.max_string_length)];
 *     ]
 *   in
 *   let actual = f @@ extract [%stri type t = Bytes.t ] in
 * 
 *   check_eq ~expected ~actual "deriving int64" *)

let test_tuple () =
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = int * int];
           [%stri type t = int * int * int];
           [%stri type t = int * int * int * int];
           [%stri type t = int * int * int * int * int];
           [%stri type t = int * int * int * int * int * int];
         ]
  in
  let expected =
    [
      [%stri
        let gen =
          QCheck2.Gen.map
            (fun (gen0, gen1) -> (gen0, gen1))
            (QCheck2.Gen.pair QCheck2.Gen.int QCheck2.Gen.int)];
      [%stri
        let gen =
          QCheck2.Gen.map
            (fun (gen0, gen1, gen2) -> (gen0, gen1, gen2))
            (QCheck2.Gen.triple QCheck2.Gen.int QCheck2.Gen.int QCheck2.Gen.int)];
      [%stri
        let gen =
          QCheck2.Gen.map
            (fun (gen0, gen1, gen2, gen3) -> (gen0, gen1, gen2, gen3))
            (QCheck2.Gen.quad
               QCheck2.Gen.int
               QCheck2.Gen.int
               QCheck2.Gen.int
               QCheck2.Gen.int)];
      [%stri
        let gen =
          QCheck2.Gen.map
            (fun ((gen0, gen1), (gen2, gen3, gen4)) ->
              (gen0, gen1, gen2, gen3, gen4))
            (QCheck2.Gen.pair
               (QCheck2.Gen.pair QCheck2.Gen.int QCheck2.Gen.int)
               (QCheck2.Gen.triple QCheck2.Gen.int QCheck2.Gen.int QCheck2.Gen.int))];
      [%stri
        let gen =
          QCheck2.Gen.map
            (fun ((gen0, gen1, gen2), (gen3, gen4, gen5)) ->
              (gen0, gen1, gen2, gen3, gen4, gen5))
            (QCheck2.Gen.pair
               (QCheck2.Gen.triple QCheck2.Gen.int QCheck2.Gen.int QCheck2.Gen.int)
               (QCheck2.Gen.triple QCheck2.Gen.int QCheck2.Gen.int QCheck2.Gen.int))];
    ]
  in

  check_eq ~expected ~actual "deriving tuples"

let test_option () =
  let expected = [ [%stri let gen = QCheck2.Gen.option QCheck2.Gen.int] ] in
  let actual = f' @@ extract' [ [%stri type t = int option] ] in
  check_eq ~expected ~actual "deriving option"

let test_array () =
  let expected = [ [%stri let gen = QCheck2.Gen.array QCheck2.Gen.int] ] in
  let actual = f' @@ extract' [ [%stri type t = int array] ] in
  check_eq ~expected ~actual "deriving option"

let test_list () =
  let expected = [ [%stri let gen = QCheck2.Gen.list QCheck2.Gen.string] ] in

  let actual = f' @@ extract' [ [%stri type t = string list] ] in
  check_eq ~expected ~actual "deriving list"

let test_alpha () =
  let expected =
    [
      [%stri let gen gen_a = gen_a];
      [%stri let gen gen_a = QCheck2.Gen.list gen_a];
      [%stri let gen gen_a = QCheck2.Gen.map (fun gen0 -> A gen0) gen_a];
      [%stri
        let gen gen_a gen_b =
          QCheck2.Gen.map
            (fun (gen0, gen1) -> A (gen0, gen1))
            (QCheck2.Gen.pair gen_a gen_b)];
      [%stri
        let gen gen_left gen_right =
          QCheck2.Gen.map
            (fun (gen0, gen1) -> (gen0, gen1))
            (QCheck2.Gen.pair gen_left gen_right)];
      [%stri
       let gen_int_tree = gen_tree QCheck2.Gen.int
      ]
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type 'a t = 'a];
           [%stri type 'a t = 'a list];
           [%stri type 'a t = A of 'a];
           [%stri type ('a, 'b) t = A of 'a * 'b];
           [%stri type ('left, 'right) t = 'left * 'right];
           [%stri type int_tree = int tree]
         ]
  in
  check_eq ~expected ~actual "deriving alpha"

let test_equal () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [
              (1, QCheck2.Gen.pure A);
              (1, QCheck2.Gen.pure B);
              (1, QCheck2.Gen.pure C);
            ]];
      [%stri
        let gen_t' =
          QCheck2.Gen.frequency
            [
              (1, QCheck2.Gen.pure A);
              (1, QCheck2.Gen.pure B);
              (1, QCheck2.Gen.pure C);
            ]];
    ]
  in
  let actual =
    f'
    @@ extract'
         [ [%stri type t = A | B | C]; [%stri type t' = t = A | B | C] ]
  in
  check_eq ~expected ~actual "deriving equal"

let test_dependencies () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [
              (1, QCheck2.Gen.map (fun gen0 -> Int gen0) SomeModule.gen);
              ( 1,
                QCheck2.Gen.map
                  (fun gen0 -> Float gen0)
                  SomeModule.SomeOtherModule.gen );
            ]];
      [%stri let gen = gen_something];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri
             type t =
               | Int of SomeModule.t
               | Float of SomeModule.SomeOtherModule.t];
           [%stri type t = (Something.t[@gen gen_something])];
         ]
  in

  check_eq ~expected ~actual "deriving dependencies"

let test_konstr () =
  let expected =
    [
      [%stri let gen = QCheck2.Gen.map (fun gen0 -> A gen0) QCheck2.Gen.int];
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [
              (1, QCheck2.Gen.map (fun gen0 -> B gen0) QCheck2.Gen.int);
              (1, QCheck2.Gen.map (fun gen0 -> C gen0) QCheck2.Gen.int);
            ]];
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [
              (1, QCheck2.Gen.map (fun gen0 -> X gen0) gen_t1);
              (1, QCheck2.Gen.map (fun gen0 -> Y gen0) gen_t2);
              (1, QCheck2.Gen.map (fun gen0 -> Z gen0) QCheck2.Gen.string);
            ]];
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [ (1, QCheck2.Gen.pure Left); (1, QCheck2.Gen.pure Right) ]];
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [
              (1, QCheck2.Gen.map (fun gen0 -> Simple gen0) QCheck2.Gen.int);
              ( 1,
                QCheck2.Gen.map
                  (fun (gen0, gen1) -> Double (gen0, gen1))
                  (QCheck2.Gen.pair QCheck2.Gen.int QCheck2.Gen.int) );
              ( 1,
                QCheck2.Gen.map
                  (fun (gen0, gen1, gen2) -> Triple (gen0, gen1, gen2))
                  (QCheck2.Gen.triple
                     QCheck2.Gen.int
                     QCheck2.Gen.int
                     QCheck2.Gen.int) );
            ]];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = A of int];
           [%stri type t = B of int | C of int];
           [%stri type t = X of t1 | Y of t2 | Z of string];
           [%stri type t = Left | Right];
           [%stri
             type t =
               | Simple of int
               | Double of int * int
               | Triple of int * int * int];
         ]
  in
  check_eq ~expected ~actual "deriving constructors"

let test_record () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.Gen.map
            (fun (gen0, gen1) -> { a = gen0; b = gen1 })
            (QCheck2.Gen.pair QCheck2.Gen.int QCheck2.Gen.string)];
      [%stri
        let gen =
          QCheck2.Gen.map
            (fun (gen0, gen1) -> { a = gen0; b = gen1 })
            (QCheck2.Gen.pair QCheck2.Gen.int QCheck2.Gen.string)];
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [
              (1, QCheck2.Gen.map (fun gen0 -> A gen0) gen_t');
              ( 1,
                QCheck2.Gen.map
                  (fun (gen0, gen1) -> B { left = gen0; right = gen1 })
                  (QCheck2.Gen.pair QCheck2.Gen.int QCheck2.Gen.int) );
            ]];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = { a : int; b : string }];
           [%stri type t = { mutable a : int; mutable b : string }];
           [%stri type t = A of t' | B of { left : int; right : int }];
         ]
  in
  check_eq ~expected ~actual "deriving record"

let test_variant () =
  let expected =
    [
      [%stri
        let gen =
          (QCheck2.Gen.frequency
             [
               (1, QCheck2.Gen.pure `A);
               (1, QCheck2.Gen.map (fun gen0 -> `B gen0) QCheck2.Gen.int);
               (1, QCheck2.Gen.map (fun gen0 -> `C gen0) QCheck2.Gen.string);
             ]
            : t QCheck2.Gen.t)];
      [%stri
        let gen_t' =
          (QCheck2.Gen.frequency [ (1, QCheck2.Gen.pure `B); (1, gen) ]
            : t' QCheck2.Gen.t)];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = [ `A | `B of int | `C of string ]];
           [%stri type t' = [ `B | t ]];
         ]
  in
  check_eq ~expected ~actual "deriving variant"

let test_tree () =
  let expected =
    [
      [%stri
       let rec gen_tree_sized gen_a n =
         match n with
         | 0 -> QCheck2.Gen.pure Leaf
         | _ ->
            QCheck2.Gen.frequency
              [
                (1, QCheck2.Gen.pure Leaf);
                ( 1,
                  QCheck2.Gen.map
                    (fun (gen0, gen1, gen2) -> Node (gen0, gen1, gen2))
                    (QCheck2.Gen.triple
                       gen_a
                       ((gen_tree_sized gen_a) (n / 2))
                       ((gen_tree_sized gen_a) (n / 2))) );
              ]
      ];
      [%stri
       let gen_tree gen_a = QCheck2.Gen.sized (gen_tree_sized gen_a)
      ];
    ]
  in
  let actual =
    f
    @@ extract [%stri type 'a tree = Leaf | Node of 'a * 'a tree * 'a tree];
  in
  check_eq ~expected ~actual "deriving tree"

let test_expr () =
  let expected =
    [
      [%stri
       let rec gen_expr_sized n =
         match n with
         | 0 -> QCheck2.Gen.map (fun gen0 -> Value gen0) QCheck2.Gen.int
         | _ ->
            QCheck2.Gen.frequency
              [
                ( 1,
                  QCheck2.Gen.map (fun gen0 -> Value gen0) QCheck2.Gen.int
                );
                ( 1,
                  QCheck2.Gen.map
                    (fun (gen0, gen1, gen2) -> If (gen0, gen1, gen2))
                    (QCheck2.Gen.triple
                       (gen_expr_sized (n / 2))
                       (gen_expr_sized (n / 2))
                       (gen_expr_sized (n / 2))) );
                ( 1,
                  QCheck2.Gen.map
                    (fun (gen0, gen1) -> Eq (gen0, gen1))
                    (QCheck2.Gen.pair (gen_expr_sized (n / 2)) (gen_expr_sized (n / 2))) );
                ( 1,
                  QCheck2.Gen.map
                    (fun (gen0, gen1) -> Lt (gen0, gen1))
                    (QCheck2.Gen.pair (gen_expr_sized (n / 2)) (gen_expr_sized (n / 2))) );
              ]
      ];
      [%stri
       let gen_expr = QCheck2.Gen.sized gen_expr_sized
      ]
    ]
  in
  let actual =
    f @@ extract
           [%stri
            type expr =
              | Value of int
              | If of expr * expr * expr
              | Eq of expr * expr
              | Lt of expr * expr]
  in
  check_eq ~expected ~actual "deriving expr"
  
let test_forest () =
  let expected =
    [
      [%stri
        let rec gen_tree_sized gen_a n =
          QCheck2.Gen.map
            (fun gen0 -> Node gen0)
            (QCheck2.Gen.map
               (fun (gen0, gen1) -> (gen0, gen1))
               (QCheck2.Gen.pair gen_a ((gen_forest_sized gen_a) (n / 2))))

        and gen_forest_sized gen_a n =
          match n with
          | 0 -> QCheck2.Gen.pure Nil
          | _ ->
             QCheck2.Gen.frequency
               [
                 (1, QCheck2.Gen.pure Nil);
                 ( 1,
                   QCheck2.Gen.map
                     (fun gen0 -> Cons gen0)
                     (QCheck2.Gen.map
                        (fun (gen0, gen1) -> (gen0, gen1))
                        (QCheck2.Gen.pair
                           ((gen_tree_sized gen_a) (n / 2))
                           ((gen_forest_sized gen_a) (n / 2)))) );
               ]
      ];
      [%stri let gen_tree gen_a = QCheck2.Gen.sized (gen_tree_sized gen_a)];
      [%stri let gen_forest gen_a = QCheck2.Gen.sized (gen_forest_sized gen_a)];
    ]
  in
  let actual =
    f
    @@ extract
         [%stri
           type 'a tree = Node of ('a * 'a forest)

           and 'a forest = Nil | Cons of ('a tree * 'a forest)]
  in
  check_eq ~expected ~actual "deriving forest"

let test_fun_primitives () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.int @-> QCheck2.Observable.int @-> o_nil)
            QCheck2.Gen.string];
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.float @-> QCheck2.Observable.float @-> o_nil)
            QCheck2.Gen.string
          ];
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.string @-> QCheck2.Observable.string @-> o_nil)
            QCheck2.Gen.string
          ];
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.bool @-> QCheck2.Observable.bool @-> o_nil)
            QCheck2.Gen.string
          ];
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.char @-> QCheck2.Observable.char @-> o_nil)
            QCheck2.Gen.string
          ];
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(QCheck2.Observable.unit @-> o_nil)
            QCheck2.Gen.string
          ];
    ]
  in

  let actual =
    f'
    @@ extract'
         [
           [%stri type t = int -> int -> string];
           [%stri type t = float -> float -> string];
           [%stri type t = string -> string -> string];
           [%stri type t = bool -> bool -> string];
           [%stri type t = char -> char -> string];
           [%stri type t = unit -> string];
         ]
  in
  check_eq ~expected ~actual "deriving fun primitives"

let test_fun_n () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.bool @-> QCheck2.Observable.int
              @-> QCheck2.Observable.float @-> QCheck2.Observable.string
              @-> QCheck2.Observable.char @-> o_nil)
            QCheck2.Gen.unit
          ];
    ]
  in
  let actual =
    f @@ extract [%stri type t = bool -> int -> float -> string -> char -> unit]
  in
  check_eq ~expected ~actual "deriving fun n"

let test_fun_option () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.option QCheck2.Observable.int @-> o_nil)
            QCheck2.Gen.unit
          ];
    ]
  in
  let actual = f @@ extract [%stri type t = int option -> unit] in
  check_eq ~expected ~actual "deriving fun option"

let test_fun_list () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.list QCheck2.Observable.int @-> o_nil)
            QCheck2.Gen.unit
          ];
    ]
  in
  let actual = f @@ extract [%stri type t = int list -> unit] in
  check_eq ~expected ~actual "deriving fun list"

let test_fun_array () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.array QCheck2.Observable.int @-> o_nil)
            QCheck2.Gen.unit
          ];
    ]
  in
  let actual = f @@ extract [%stri type t = int array -> unit] in
  check_eq ~expected ~actual "deriving fun array"

let test_fun_tuple () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.pair QCheck2.Observable.int QCheck2.Observable.int
              @-> o_nil)
            QCheck2.Gen.unit
          ];
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.triple
                QCheck2.Observable.int
                QCheck2.Observable.int
                QCheck2.Observable.int
              @-> o_nil)
            QCheck2.Gen.unit
          ];
      [%stri
        let gen =
          QCheck2.fun_nary
            QCheck2.Tuple.(
              QCheck2.Observable.quad
                QCheck2.Observable.int
                QCheck2.Observable.int
                QCheck2.Observable.int
                QCheck2.Observable.int
              @-> o_nil)
            QCheck2.Gen.unit
          ];
    ]
  in
  let actual =
    f'
    @@ extract'
         [
           [%stri type t = int * int -> unit];
           [%stri type t = int * int * int -> unit];
           [%stri type t = int * int * int * int -> unit];
         ]
  in
  check_eq ~expected ~actual "deriving fun tuple"

let test_weight_konstrs () =
  let expected =
    [
      [%stri
        let gen =
          QCheck2.Gen.frequency
            [
              (5, QCheck2.Gen.pure A);
              (6, QCheck2.Gen.pure B);
              (1, QCheck2.Gen.pure C);
            ]];
    ]
  in
  let actual =
    f @@ extract [%stri type t = A [@weight 5] | B [@weight 6] | C]
  in
  check_eq ~expected ~actual "deriving weight konstrs"

(* Regression test: https://github.com/c-cube/qcheck/issues/187 *)
let test_recursive_poly_variant () =
  let expected =
    [
      [%stri
       let rec gen_tree_sized gen_a n =
         (match n with
         | 0 -> QCheck2.Gen.map (fun gen0 -> `Leaf gen0) gen_a
         | _ ->
            QCheck2.Gen.frequency
              [
                ( 1,
                  QCheck2.Gen.map (fun gen0 -> `Leaf gen0) gen_a
                );
                ( 1,
                  QCheck2.Gen.map
                    (fun gen0 -> `Node gen0)
                    (QCheck2.Gen.map
                       (fun (gen0, gen1) -> (gen0, gen1))
                       (QCheck2.Gen.pair
                          ((gen_tree_sized gen_a) (n / 2))
                          ((gen_tree_sized gen_a) (n / 2))))
                );
              ]
            : tree QCheck2.Gen.t)];
      [%stri
       let gen_tree gen_a = QCheck2.Gen.sized (gen_tree_sized gen_a)
      ]
    ]
  in
  let actual =
    f @@ extract [%stri type 'a tree = [ `Leaf of 'a | `Node of 'a tree * 'a tree ]]
  in
  check_eq ~expected ~actual "deriving recursive polymorphic variants"

let () =
  Alcotest.(
    run
      "ppx_deriving_qcheck tests"
      [
        ( "deriving generator good",
          [
            test_case "deriving int" `Quick test_int;
            test_case "deriving float" `Quick test_float;
            test_case "deriving char" `Quick test_char;
            test_case "deriving string" `Quick test_string;
            test_case "deriving unit" `Quick test_unit;
            test_case "deriving bool" `Quick test_bool;
            test_case "deriving int32" `Quick test_int32;
            test_case "deriving int32'" `Quick test_int32';
            test_case "deriving int64" `Quick test_int64;
            test_case "deriving int64'" `Quick test_int64';
            (* test_case "deriving bytes" `Quick test_bytes; *)
            test_case "deriving tuple" `Quick test_tuple;
            test_case "deriving option" `Quick test_option;
            test_case "deriving array" `Quick test_array;
            test_case "deriving list" `Quick test_list;
            test_case "deriving constructors" `Quick test_konstr;
            test_case "deriving dependencies" `Quick test_dependencies;
            test_case "deriving record" `Quick test_record;
            test_case "deriving equal" `Quick test_equal;
            test_case "deriving tree like" `Quick test_tree;
            test_case "deriving expr like" `Quick test_expr;
            test_case "deriving alpha" `Quick test_alpha;
            test_case "deriving variant" `Quick test_variant;
            test_case "deriving weight constructors" `Quick test_weight_konstrs;
            test_case "deriving forest" `Quick test_forest;
            test_case "deriving fun primitives" `Quick test_fun_primitives;
            test_case "deriving fun option" `Quick test_fun_option;
            test_case "deriving fun array" `Quick test_fun_array;
            test_case "deriving fun list" `Quick test_fun_list;
            test_case "deriving fun n" `Quick test_fun_n;
            test_case "deriving fun tuple" `Quick test_fun_tuple;
            test_case
              "deriving rec poly variants"
              `Quick
              test_recursive_poly_variant;
          ] );
      ])
