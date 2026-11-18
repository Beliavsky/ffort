! SPDX-License-Identifier: MIT
program p
  implicit none
  call f()
contains
  subroutine f(x)
    real(8), optional, intent(in) :: x
    print *, kind(atan(x))
  end subroutine
end program p
