module operations
  implicit none
  interface twice
    module procedure twice_i, twice_r
  end interface twice
contains
  elemental integer function twice_i(x) result(y)
    integer, intent(in) :: x
    y = 2*x
  end function
  elemental real(kind=8) function twice_r(x) result(y)
    real(kind=8), intent(in) :: x
    y = 2*x
  end function
end module
program main
  use operations
  implicit none
  real(kind=8)::x(3)=[1d0,2d0,3d0]
  integer::a(3)=[1,2,3]
  print *,twice(x**2),twice(a+1)
end program
