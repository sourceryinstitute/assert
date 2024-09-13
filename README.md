Assert
======

A simple assertion utility taking advantage of the Fortran 2018 standard's introduction of variable stop codes
and error termination inside pure procedures.

Motivations
-----------
1. To mitigate against a reason developers often cite for not writing `pure` procedures: their inability to produce output in normal execution.
2. To promote the enforcement of programming contracts.

Overview
--------
This assertion utility contains three public entities:

1. An `assert` subroutine,
2. A `characterizable_t` abstract type supporting `assert`, and
3. An `intrinsic_array_t` non-abstract type extending `characterizable_t`.

The `assert` subroutine

* Error-terminates with a variable stop code when a user-defined logical assertion fails,
* Includes user-supplied diagnostic data in the output if provided by the calling procedure,
* Is callable inside `pure` procedures, and
* Can be eliminated during an optimizing compiler's dead-code removal phase based on a preprocessor macro: `-DUSE_ASSERTIONS=.false.`.

The `characterizable_t` type defines an `as_character()` deferred binding that produces `character` strings for use as diagnostic output from a user-defined derived type that extends  `characterizable_t` and implements the deferred binding.

The `intrinsic_array_t` type that extends `characterizable_t` provides a convenient mechanism for producing diagnostic output from arrays of intrinsic type `complex`, `integer`, `logical`, or `real`.

Use Cases
---------
Two common use cases include

1. [Enforcing programming contracts] throughout a project via runtime checks.
2. Producing output in `pure` procedures for debugging purposes.

### Enforcing programming contracts
Programming can be thought of as requirements for correct execution of a procedure and assurances for the result of correct execution.
The requirements and assurances might be constraints of three kinds:

1. **Preconditions (requirements):** `logical` expressions that must evaluate to `.true.` when a procedure starts execution,
2. **Postconditions (assurances):** expressions that must evaluate to `.true.` when a procedure finishes execution, and
3. **Invariants:** universal pre- and postconditions that must always be true when all procedures in a class start or finish executing.

The [examples/README.md] file shows examples of writing constraints in notes on class diagrams using the formal syntax of the Object Constraint Language ([OCL]).

Downloading, Building, and Running Examples
-------------------------------------------

### Downloading Assert
```
git clone git@github.com:berkeleylab/assert
cd assert
```

### Building and testing with `gfortran`
#### Single-image (serial) execution
The following command builds Assert and runs the full test suite in a single image:
```
fpm test --profile release
```
which builds the Assert library and runs the test suite.

#### Multi-image (parallel) execution
With `gfortran` and OpenCoarrays installed,
```
fpm test --compiler caf --profile release --runner "cafrun -n 2"
```
To build and test with the Numerical Algorithms Group (NAG) Fortran compiler version
7.1 or later, use
```
fpm test --compiler=nagfor --profile release --flag "-coarray=cosmp -fpp -f2018"
```

### Building and testing with the Intel `ifx` compiler
```
fpm test --compiler ifx --profile release --flag -coarray
```
### Building and testing with the LLVM `flang-new` compiler
```
fpm test --compiler flang-new --flag "-mmlir -allow-assumed-rank -O3"

```

### Building and testing with the Numerical Algorithms Group (NAG) compiler
```
fpm test --compiler nagfor --profile release --flag "-fpp -coarray=cosmp"
```

### Building and testing with the Cray Compiler Environment (CCE)
Because `fpm` uses the compiler name to determine the compiler identity and because
CCE provides one compiler wrapper, `ftn`, for invoking all compilers, you will
need to invoke `ftn` in a shell script named to identify CCE compiler. For example,
place a script named `crayftn.sh` in your path with the following contents and with
executable privileges set appropriately:
```
#!/bin/bash

ftn $@
```
Then build and test Assert with the command
```
fpm test --compiler crayftn.sh --profile release
```


### Building and testing with other compilers
To use Assert with other compilers, please submit an issue or pull request.  

### Running the examples
See the [./example](./example) subdirectory.

Documentation
-------------

See [Assert's GitHub Pages site] for HTML documentation generated with [`ford`].

For further documentation, please see [example/README.md] and the [tests].  Also, the code in [src] has comments formatted for generating HTML documentation using [FORD].

### Potential pitfalls of `call_assert` macros:

The `call_assert*` macros from the `assert_macros.h` header file provide the
attractive guarantee that they will always compile *completely* away when
assertions are disabled, regardless of compiler analyses and optimization
level. This means users can reap the maintainability and correctness benefits
of aggressively asserting invariants throughout their code, without needing to
balance any potential performance cost associated with such assertions when the
code runs in production.

Unfortunately, C-preprocessor macros do not integrate cleanly with some aspects
of the Fortran language. As such, you might encounter one or more of the
following pitfalls when using these macros.

#### Line length limit

Up to and including the Fortran 2018 language standard, compilers were only
required to support up to 132 characters per free-form source line.
Preprocessor macro invocations are always expanded to a single line during
compilation, so when passing non-trivial arguments to macros including
`call_assert*` it becomes easy for the expansion to exceed this line length
limit. This can result in compile-time errors like the following from gfortran:

```
Error: Line truncated at (1) [-Werror=line-truncation]
```

Some compilers offer a command-line argument that can be used to workaround this legacy limit, eg:

* `gfortran -ffree-line-length-0` aka `gfortran -ffree-line-length-none`

When using `fpm`, one can pass such a flag to the compiler using the `fpm --flag` option, eg:

```shell
$ fpm test --profile release --flag -ffree-line-length-0
```

Thankfully Fortran 2023 raised this obscolecent line limit to 10,000
characters, so by using newer compilers you might never encounter this problem.

#### Line breaks in macro invocations

As mentioned above, preprocessor macro invocations are always expanded to a
single line, no matter how many lines were used by the invocation.  This means
it's problematic to invoke the `call_assert*` macros with code like the
following:

```fortran
! INCORRECT: don't use & line continuations!
call_assert_diagnose( computed_checksum == expected_checksum, &
                      "Checksum mismatch failure!", &
                      expected_checksum )                  
```
When the preprocessor expands the macro invocation above, the `&` characters
above are not interpreted as Fortran line continuations. Instead they are
inserted into the middle of the single-line macro expansion, where they will
(likely) create a confusing syntax error.

Instead when breaking long lines in a macro invocation, just break the line (no
continuation character!), eg:

```fortran
! When breaking a lines in a macro invocation, just use new-line with no `&` continuation character:
call_assert_diagnose( computed_checksum == expected_checksum,
                      "Checksum mismatch failure!",
                      expected_checksum )                  
```

#### Comments in macro invocations

Fortran does not support comments with an end delimiter,
only to-end-of-line comments.  As such, there is no way to safely insert a
Fortran comment into the middle of a macro invocation.  For example, the
following seemingly reasonable code results in a syntax error
after macro expansion:

```fortran
! INCORRECT: cannot use Fortran comments inside macro invocation
call_assert_diagnose( computed_checksum == expected_checksum, ! ensured since version 3.14
                      "Checksum mismatch failure!",           ! TODO: write a better message here
                      computed_checksum )             
```

Depending on your compiler it *might* be possible to use a C-style block
comment (because they are removed by the preprocessor), for example with
gfortran one can instead write the following:

```fortran
call_assert_diagnose( computed_checksum == expected_checksum, /* ensured since version 3.14 */
                      "Checksum mismatch failure!",           /* TODO: write a better message here */
                      computed_checksum )
```

However that capability might not be portable to other Fortran compilers. 
When in doubt, one can always move the comment outside the macro invocation:

```fortran
! assert a property ensured since version 3.14
call_assert_diagnose( computed_checksum == expected_checksum, 
                      "Checksum mismatch failure!",           
                      computed_checksum ) ! TODO: write a better message above
```                      

Legal Information
-----------------
See the [LICENSE](LICENSE) file for copyright and licensing information.

[Hyperlinks]:#
[OpenCoarrays]: https://github.com/sourceryinstitute/opencoarrays
[Enforcing programming contracts]: #enforcing-programming-contracts
[Single-image execution]: #single-image-execution
[example/README.md]: ./example/README.md
[tests]: ./tests
[src]: ./src
[FORD]: https://github.com/Fortran-FOSS-Programmers/ford
[Fortran Package Manager]: https://github.com/fortran-lang/fpm
[OCL]: https://en.wikipedia.org/wiki/Object_Constraint_Language
[Assert's GitHub Pages site]: https://berkeleylab.github.io/assert/
[`ford`]: https://github.com/Fortran-FOSS-Programmers/ford
