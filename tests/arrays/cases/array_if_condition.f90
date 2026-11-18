program probe
implicit none
logical :: flag(2)
integer :: a(2)
flag(1)=.true.
flag(2)=.false.
a(1)=1
a(2)=2
if(flag(1)) then
 a(1)=7
else
 a(1)=9
end if
if(flag(2)) then
 a(2)=9
end if
print *,a(1),a(2)
end program probe
