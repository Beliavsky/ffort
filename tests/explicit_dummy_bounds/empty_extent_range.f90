program main
implicit none
integer::a(0,0)
call work(a,2147483647)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(out)::x(-1:n,0)
print *,size(x)
end subroutine
end program
