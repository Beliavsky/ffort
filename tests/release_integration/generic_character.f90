module operations
  implicit none
  private
  public :: twice
  interface twice
    module procedure twice_character, twice_integer
  end interface twice
contains
  character(4) function twice_character(x) result(y)
    character(2), intent(in) :: x
    y = x // x
  end function
  integer function twice_integer(x) result(y)
    integer, intent(in) :: x
    y = 2*x
  end function
end module
program main
  use operations, only: twice
  implicit none
  character(2), parameter :: names(2)=[character(2)::'a','bc']
  character(5) :: decorated(2)
  decorated='>' // [twice(names(1)),twice(names(2))]
  print '(a,a,i0)',decorated(1),decorated(2),twice(7)
end program
