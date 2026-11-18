module m
contains
pure logical function more(x)
integer,intent(in)::x
more=x<3
end function
end module
use m
implicit none
integer::i
i=0
do while(more(i))
i=i+1
end do
print "(i0)",i
end
