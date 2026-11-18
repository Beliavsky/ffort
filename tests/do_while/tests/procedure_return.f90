module m
contains
integer function f()
integer::i
i=0
do while(.true.)
i=i+1
if(i==3) then
f=i
return
end if
end do
end function
end module
use m
implicit none
print "(i0)",f()
end
