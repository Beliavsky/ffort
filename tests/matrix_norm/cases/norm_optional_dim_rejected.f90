program p
call s(1)
contains
subroutine s(d)
integer,optional,intent(in)::d
real::x(2)
x=[3.,4.]
print *,norm2(x,d)
end subroutine
end program
