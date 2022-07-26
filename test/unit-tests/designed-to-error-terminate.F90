program designed_to_error_terminate
  !! Test assertions that are intended to error terminate
  use assert_m, only : assert
  
#ifdef USE_CAFFEINE
   use caffeine_m, only : this_image => caf_this_image, co_reduce => caf_co_reduce
#endif
  
  implicit none
  
  integer exit_status

  call execute_command_line( &
    command = "fpm run --example intentionally_false_assertions > /dev/null 2>&1", &
    wait = .true., &
    exitstat = exit_status &
  )
    
  block
    logical error_termination

    error_termination = exit_status /=0

    call co_all(error_termination)

    if (this_image()==1) then

      if (error_termination) then
        print *, "----> All tests designed to error-terminate pass.    <----"
      else 
        print *, "----> One or more tests designed to error-terminate terminated normally. Yikes! Who designed this OS? <----"
      end if

    end if

  end block

contains

  pure function and(lhs,rhs) result(lhs_and_rhs)
    logical, intent(in) :: lhs, rhs
    logical lhs_and_rhs

    lhs_and_rhs = lhs .and. rhs

  end function

  subroutine co_all(boolean)
    logical, intent(inout) :: boolean

    call co_reduce(boolean, and)

  end subroutine

end program
