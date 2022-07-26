program designed_to_terminate_normally
  !! Test assertions expected to succeed
  use assert_m, only : assert
  use intrinsic_array_m, only : intrinsic_array_t
  
#ifdef USE_CAFFEINE
   use caffeine_m, only : this_image => caf_this_image, sync all => caf_sync_all
#endif

  implicit none

  scalar_diagnostic_data: &
  block
    complex, parameter :: z = (1.,1.)
    integer, parameter :: n = 1
    logical, parameter :: bool = .true.
    real, parameter :: x = 1.
    
    call assert(abs(z)>0, "main: z>0", diagnostic_data = z)
    call assert(n>0, "main: i>0") 
    call assert(n>0, "main: n>0", n)
    call assert(x>0., "main: x>0", x)
    call assert(bool, "main: z>0", bool)

  end block scalar_diagnostic_data
  
  array_diagnostic_data: &
  block
    complex, parameter :: complex_array(*) = [(1.,0.), (0.,1.)]
    integer, parameter :: integer_array(*) = [1, 2]
    logical, parameter :: logical_array(*) = [.true., .true.]
    real, parameter :: real_array(*) = [1., 2.]

    call assert(all(abs(complex_array) < 2.), "main: all(abs(complex_array) < 2.)", intrinsic_array_t(complex_array))
    call assert(all(integer_array < 3), "main: all(int_array < 3)", intrinsic_array_t(integer_array))
    call assert(all(logical_array), "main: all(logical_array)", intrinsic_array_t(logical_array))
    call assert(all(real_array < 3.), "main: all(real_array < 3.)", intrinsic_array_t(real_array))

  end block array_diagnostic_data

  sync all

  if (this_image()==1) print *, "----> All tests designed to terminate normally pass. <----"

end program designed_to_terminate_normally
