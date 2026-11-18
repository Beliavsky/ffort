program main
implicit none
integer::a(2,2)
a=1
call work(a,2)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n,:)
return
end subroutine
end program
