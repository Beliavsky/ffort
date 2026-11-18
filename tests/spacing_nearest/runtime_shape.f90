program p
implicit none

call s(3)
contains
subroutine s(n)
integer,intent(in)::n
real::x(n)
x=1
print *,spacing(x)==epsilon(1.)
print *,nearest(x,-1.)<x
end subroutine
end program
