module optional_utilities
implicit none
integer, parameter :: dp=selected_real_kind(15,307)
contains
elemental function default_integer(def,opt) result(ii)
! return opt if it is present, otherwise def (integer arguments and result)
integer, intent(in)           :: def
integer, intent(in), optional :: opt
integer                       :: ii
if (present(opt)) then
   ii = opt
else
   ii = def
end if
end function default_integer
!
elemental function default_real(def,opt) result(yy)
! return opt if it is present, otherwise def (real arguments and result)
real(kind=dp), intent(in)           :: def
real(kind=dp), intent(in), optional :: opt
real(kind=dp)                       :: yy
if (present(opt)) then
   yy = opt
else
   yy = def
end if
end function default_real
!
elemental function default_logical(def,opt) result(tf)
! return opt if it is present, otherwise def (logical arguments and result)
logical, intent(in)           :: def
logical, intent(in), optional :: opt
logical                       :: tf
if (present(opt)) then
   tf = opt
else
   tf = def
end if
end function default_logical
!
pure function present_and_true(xx) result(tf)
logical, intent(in), optional :: xx
logical                       :: tf
if (present(xx)) then
   tf = xx
else
   tf = .false.
end if
end function present_and_true
!
elemental subroutine set_optional_integer(i,idef,iopt)
! set i to (iopt,idef) if iopt (is,is not) PRESENT
integer, intent(out)          :: i
integer, intent(in)           :: idef
integer, intent(in), optional :: iopt
if (present(iopt)) then
   i = iopt
else
   i = idef
end if
end subroutine set_optional_integer
!
elemental subroutine set_optional_real(xx,xdef,xopt)
! set xx to (xopt,xdef) if xopt (is,is not) PRESENT
real(kind=dp), intent(out)          :: xx
real(kind=dp), intent(in)           :: xdef
real(kind=dp), intent(in), optional :: xopt
if (present(xopt)) then
   xx = xopt
else
   xx = xdef
end if
end subroutine set_optional_real
!
elemental subroutine set_optional_logical(xx,xdef,xopt)
! set xx to (xopt,xdef) if xopt (is,is not) PRESENT
logical, intent(out)          :: xx
logical, intent(in)           :: xdef
logical, intent(in), optional :: xopt
if (present(xopt)) then
   xx = xopt
else
   xx = xdef
end if
end subroutine set_optional_logical
!
end module
program exercise_optional_utilities
use optional_utilities
implicit none
integer :: i,ia(3)
real(dp) :: x,xa(3)
logical :: tf,ta(3)
print *, default_integer(10),default_integer(10,20),default_integer(opt=30,def=10)
print *, default_real(1.5_dp),default_real(opt=2.5_dp,def=1.5_dp)
print *, default_logical(.true.),default_logical(.false.,.true.)
print *, present_and_true(),present_and_true(.true.),present_and_true(.false.)
print *, default_integer([1,2,3]),default_integer([1,2,3],9)
print *, default_real([1.0_dp,2.0_dp,3.0_dp])
print *, default_logical([.true.,.false.,.true.],.false.)
call set_optional_integer(i,5)
call set_optional_real(x,1.25_dp)
call set_optional_logical(tf,.true.)
print *, i,x,tf
call set_optional_integer(ia,[1,2,3])
call set_optional_real(xa,[1.0_dp,2.0_dp,3.0_dp],4.5_dp)
call set_optional_logical(ta,[.true.,.false.,.true.])
print *, ia,xa,ta
call set_optional_integer(iopt=7,i=i,idef=5)
call set_optional_real(xopt=2.5_dp,xx=x,xdef=1.25_dp)
call set_optional_logical(xopt=.false.,xx=tf,xdef=.true.)
print *, i,x,tf
end program
