module m
implicit none
character(:),allocatable :: x(:)
contains
impure elemental function shrink(dummy) result(text)
integer,intent(in)::dummy
character(1)::text
deallocate(x)
allocate(character(1)::x(1))
x='Q'
text='Z'
end function
end module
use m
implicit none
allocate(character(5)::x(1))
x='abcde'
x(1)(3:5)=shrink(1)
end
