module m
implicit none
contains
impure elemental integer function echo(x)
integer,intent(in)::x
print *,x
echo=x
end function
end module
program main
use m
implicit none
integer::a(2,2),b(2)
a=reshape([4,1,1,2],[2,2])
b=minloc(echo(a),back=.true.)
print *,b
end program
