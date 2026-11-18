! SPDX-License-Identifier: MIT
program p
  implicit none
  call f()
contains
  subroutine f(x)
    real(8), optional, intent(in) :: x
    print *, kind(atan2(x,1d0))
  end subroutine
end program p
