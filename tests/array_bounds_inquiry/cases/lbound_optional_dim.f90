program main
call s(1)
contains
subroutine s(d)
integer,optional,intent(in)::d
real::x(2)
print *,lbound(x,d)
end subroutine
end program
