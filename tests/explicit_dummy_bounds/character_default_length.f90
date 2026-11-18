program main
implicit none
character::a(4)
a=['a','b','c','d']
call work(a,2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
character,intent(inout)::x(n)
print *,len(x),size(x)
x='q'
end subroutine
end program
