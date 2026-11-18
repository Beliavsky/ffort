module m
implicit none
type::box
 integer::x=3
contains
 procedure::text
end type
contains
character(2) function text(this) result(s)
 class(box),intent(in)::this
 write(s,'(i2.2)')this%x
end function
character(2) function plain(b) result(s)
 type(box),intent(in)::b
 write(s,'(i2.2)')b%x
end function
character(2) function number(n) result(s)
 integer,intent(in)::n
 write(s,'(i2.2)')n
end function
function make(n) result(b)
 integer,intent(in)::n
 type(box)::b
 b=box(n)
end function
recursive function chain(n) result(b)
 integer,intent(in)::n
 type(box)::b
 if(n==0)then
  b=box(3)
 else
  b=chain(n-1)
 endif
end function
character(2) function forbidden(b) result(s)
 type(box),intent(in)::b
 error stop 77
 s='NO'
end function
end module
program p
use m
implicit none
type(box)::b,c
character(2)::a(2)
integer::i
b=box(3)
c=box(6)
a=[number(sum([b%x])),number(sum([b%x]))]
write(*,"(2a)")a
end program
