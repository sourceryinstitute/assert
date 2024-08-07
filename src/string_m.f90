module string_m
  implicit none

contains  

   pure function string(number) result(number_as_string)
    integer, intent(in) :: number
    integer, parameter :: max_len=128
    character(len=max_len) :: untrimmed_string
    character(len=:), allocatable :: number_as_string

    write(untrimmed_string, *) number
    number_as_string = trim(adjustl(untrimmed_string))
  end function

end module string_m
