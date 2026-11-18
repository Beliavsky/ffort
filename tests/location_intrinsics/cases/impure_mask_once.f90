module m
implicit none
contains
impure elemental logical function keep(x)
integer,intent(in)::x
print *,x
keep=x>0
end function
end module
program main
use m
implicit none
integer::a(2,2),b(2)
a=reshape([4,-1,2,2],[2,2])
b=minloc(a,mask=keep(a),back=.true.)
print *,b
end program
