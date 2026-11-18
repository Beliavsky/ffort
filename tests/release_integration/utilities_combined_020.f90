module utility_operators
implicit none
private
public::operator(.in.),operator(.notall.)
interface operator(.in.)
module procedure int_in_vec
end interface
interface operator(.notall.)
module procedure notall
end interface
contains
pure function int_in_vec(i,ivec) result(tf)
integer, intent(in) :: i,ivec(:)
logical             :: tf
tf = (any(i == ivec))
end function int_in_vec
pure function notall(ivec) result(tf)
logical, intent(in) :: ivec(:)
logical             :: tf
tf = .not. all(ivec)
end function notall
end module

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

module kind_mod
implicit none
private
public :: dp,bad_real,long_int,i32,i64,bad_int
integer, parameter :: sp = selected_real_kind(6, 37)   ! single precision
integer, parameter :: dp = selected_real_kind(15, 307) ! double precision
integer, parameter :: qp = selected_real_kind(32)      ! quadruple precision
real(kind=dp), parameter :: bad_real = -999.0_dp
integer, parameter :: i32=selected_int_kind(9), long_int = selected_int_kind(15), i64 = long_int, &
                      bad_int = -999
end module kind_mod
module util_mod
use kind_mod,only:dp,long_int,i64
implicit none
private
public::probe
real(kind=dp)    , parameter :: tiny_real = 1.0d-10, pi = 3.141592653589793238462643_dp, &
                                bad_real = -999.0_dp
integer          , parameter :: itrue = 1, ifalse = 0, istdin = 5, istdout = 6, bad_unit=-1, bad_int = -999
contains
function probe(x) result(y)
real(dp),intent(in)::x
real(dp)::y
y=x+pi
end function
end module

module integrated_utilities
use utility_operators,only:operator(.in.),operator(.notall.)
use optional_utilities,only:default_integer,default_real,present_and_true,set_optional_integer
use kind_mod,only:dp,i64
use util_mod,only:probe
implicit none
contains
function score(a,limit) result(value)
integer,intent(in)::a(:)
integer,intent(in),optional::limit
integer(i64)::value,j
value=0_8
if(any(a<0)) then
 value=-1_8
else if(all(a>0)) then
 outer: do j=1_8,int(size(a),kind=8)
  if(a(j) .in. [3,7]) cycle outer
  if(a(j)>default_integer(4,limit)) exit outer
  value=value+int(a(j),kind=8)
 end do outer
 value=value+count(a>3,kind=8)
else
 value=-2_8
end if
end function
function adjusted(x) result(y)
real(dp),intent(in)::x
real(dp)::y
y=probe(default_real(x))+dble(merge(2,3,.true.))
end function
end module
program main
use integrated_utilities,only:score,adjusted
use utility_operators,only:operator(.in.),operator(.notall.)
use optional_utilities,only:default_integer,present_and_true,set_optional_integer
implicit none
integer::a(4),b(3)
a=[1,3,5,7]
print *,3 .in. a,2 .in. a,.notall. [ .true.,.false. ],.notall. [ .true.,.true. ]
print *,score(a),score(a,limit=8),score([-1,2])
call set_optional_integer(b,[2,4,6])
print *,b,default_integer(10),default_integer(opt=12,def=10)
print *,present_and_true(),present_and_true(.true.)
print *,adjusted(2.0_8)
print *,all(a>0),any(a<0),count(a>3,kind=8),dble(count(a>3))
end program
