# Changes

## 2022/02/10

* Remove `Makefile.coq` and use `coq_makefile` instead. The `.coq-native`
  directories, which were not installed in previous releases, should now
  be installed, so `coq-menhirlib` should work with versions of Coq that
  have enabled `native_compute` at configuration time.

## 2021/09/28

* Change `Instance` to `Global Instance` in the library and in the
  Coq files produced by `menhir --coq`
  so as to avoid warnings with Coq 8.14.

## 2021/04/19

* The types returned by the parsing functions, `parse_result` and
  `step_result` have been extended to carry additional information
  returned during failure. `Fail_pr` (resp. `Fail_sr`) is now an
  abbreviation for `Fail_pr_full _ _` (resp. `Fail_sr_full _ _`), and
  `Fail_pr_full` (resp. `Fail_sr_full`) contains a payload of the
  parser's state and the most recent token when the failure occurred.
  This enables error reporting in the Coq parsers generated by Menhir.
  (Contributed by Brian Ward.)

## 2021/03/10

* Replace `Require Omega` with `Require ZArith`
  so as to guarantee compatibility with Coq 8.14.

* Change `Hint` to `Global Hint` in several places,
  so as to avoid warnings with Coq 8.13.

## 2020/05/03

* Import `ListNotations` wherever it is necessary so that we do not rely
  on it being exported by `Program`.

## 2019/09/24

* Fix compatibility with Coq 8.10, and avoid some warnings.

## 2019/06/26

* Fix compatibility with Coq 8.7 and Coq 8.9:
  * In Coq 8.7, in the syntax `{ x : T & T' }` for the `sigT` types,
    it was not possible to omit the type `T`.
  * An anomaly in Coq 8.7 has been worked around.
  * In Coq 8.9, the numeral notation for positives moved from
    `Coq.Numbers.BinNums` to `Coq.PArith.BinPos`.

## 2019/06/13

* The Coq development is now free of any axiom (it used to use axiom
  `K`), and the parsers can now be executed directly within Coq, without
  using extraction.

* The parser interpreter is now written using dependent types, so that
  no dynamic checks are needed anymore at parsing time. When running
  the extracted code, this should give a performance boost. Moreover,
  efficient extraction of `int31` is no longer needed. This required
  some refactoring of the type of parse trees.

* Instead of a dependent pair of a terminal and a semantic
  value, tokens are now a user-defined (inductive) type.

## 2018/08/27

* Avoid an undocumented mode of use of the `fix` tactic,
  which would cause an incompatibility with Coq > 8.8.1.
  (Reported and corrected by Michael Soegtrop.)

## 2018/05/30

* Initial release.