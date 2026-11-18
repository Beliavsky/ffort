program control
implicit none
integer :: n
n=0
if(touch(1)) then
 n=1
else if(touch(2)) then
 n=2
else if(touch(3)) then
 n=3
end if
print *,n
contains
impure elemental logical function touch(x) result(ok)
integer,intent(in)::x
print *,x
ok=.true.
end function
end program
