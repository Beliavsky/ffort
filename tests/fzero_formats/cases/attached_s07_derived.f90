module vec_mod
  implicit none
  type :: vec2
     real(8) :: x = 0, y = 0
  contains
     procedure :: norm => vec_norm
  end type vec2
  interface operator(+)
     module procedure vadd
  end interface
  interface operator(.dot.)
     module procedure vdot
  end interface
contains
  pure function vadd(a, b) result(c)
    type(vec2), intent(in) :: a, b
    type(vec2) :: c
    c%x = a%x + b%x
    c%y = a%y + b%y
  end function vadd
  pure real(8) function vdot(a, b)
    type(vec2), intent(in) :: a, b
    vdot = a%x*b%x + a%y*b%y
  end function vdot
  real(8) function vec_norm(self)
    class(vec2), intent(in) :: self
    vec_norm = sqrt(self%x**2 + self%y**2)
  end function vec_norm
end module vec_mod
program derived2
  use vec_mod
  implicit none
  type(vec2) :: a, b, c
  a = vec2(3, 4)
  b = vec2(1.5d0, -2d0)
  c = a + b
  print '(2f8.3)', c%x, c%y
  print '(f8.3)', a .dot. b
  print '(f8.3)', a%norm()
  c = vec2()
  print '(2f8.3)', c%x, c%y
end program derived2
