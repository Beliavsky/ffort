program main
implicit none
character(0)::a(1,2,3)
a=''
call work(a,2)
contains
subroutine work(x,n)
integer,intent(in)::n
character(*),intent(inout)::x(n,1,n)
x='ignored'
print *,shape(x),len(x),size(x)
end subroutine
end program
