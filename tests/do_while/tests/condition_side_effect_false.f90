module m
implicit none
integer::calls=0
contains
impure elemental logical function more(x)
integer,intent(in)::x
calls=calls+1
more=x<0
end function
end module
use m
implicit none
integer::i
i=0
do while(more(i))
i=i+1
cycle
end do
print "(i0,1x,i0)",i,calls
end
