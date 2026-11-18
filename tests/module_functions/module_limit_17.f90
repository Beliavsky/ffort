module m1
contains
function f1(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function f1
end module m1
module m2
contains
function f2(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+2
end function f2
end module m2
module m3
contains
function f3(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+3
end function f3
end module m3
module m4
contains
function f4(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+4
end function f4
end module m4
module m5
contains
function f5(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+5
end function f5
end module m5
module m6
contains
function f6(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+6
end function f6
end module m6
module m7
contains
function f7(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+7
end function f7
end module m7
module m8
contains
function f8(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+8
end function f8
end module m8
module m9
contains
function f9(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+9
end function f9
end module m9
module m10
contains
function f10(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+10
end function f10
end module m10
module m11
contains
function f11(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+11
end function f11
end module m11
module m12
contains
function f12(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+12
end function f12
end module m12
module m13
contains
function f13(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+13
end function f13
end module m13
module m14
contains
function f14(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+14
end function f14
end module m14
module m15
contains
function f15(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+15
end function f15
end module m15
module m16
contains
function f16(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+16
end function f16
end module m16
module m17
contains
function f17(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+17
end function f17
end module m17
program main
use m1
use m2
use m3
use m4
use m5
use m6
use m7
use m8
use m9
use m10
use m11
use m12
use m13
use m14
use m15
use m16
use m17
print *, f1(1)
end program main
