program p
call s(1)
contains
subroutine s(d)
integer,optional,intent(in)::d
real::x(2)
x=[3.,4.]
if(norm2(x,(d))/=5.) error stop 1
end subroutine
end program
