! assert_macros.h: provides preprocessor-based assertion macros
! that are guaranteed to compile away statically when disabled.

! Enable repeated includes to toggle assertions based on current settings:
#undef call_assert
#undef call_assert_describe
#undef call_assert_diagnose

#ifndef ASSERTIONS
! Assertions are off by default
#define ASSERTIONS 0
#endif

! Deal with stringification issues:
! https://gcc.gnu.org/legacy-ml/fortran/2009-06/msg00131.html
#ifndef STRINGIFY
# if defined(__GFORTRAN__) || defined(_CRAYFTN)
#  define STRINGIFY(x) "x"
# else
#  define STRINGIFY(x) #x
# endif
#endif

#if ASSERTIONS
# define call_assert(assertion) call assert(assertion, "call_assert(" // STRINGIFY(assertion) // ") in file " // __FILE__ // ", line " // string(__LINE__))
# define call_assert_describe(assertion, description) call assert(assertion, description // " in file " // __FILE__ // ", line " // string(__LINE__))
# define call_assert_diagnose(assertion, description, diagnostic_data) call assert(assertion, description // " in file " // __FILE__ // ", line " // string(__LINE__), diagnostic_data)
#else
# define call_assert(assertion)
# define call_assert_describe(assertion, description)
# define call_assert_diagnose(assertion, description, diagnostic_data)
#endif
