module m
implicit none
type::dt
character(len=32768)::s="cat"
end type
contains
recursive function count_down(n) result(y)
integer,intent(in)::n
integer::y
type(dt)::local
if(local%s/="cat")error stop "fresh"
if(n<=0)then
y=0
else
y=count_down(n-1)
end if
end function
end module
program main
use m
implicit none
print*,count_down(60)
end
