program main
implicit none
character(0)::a(4)
a=''
call work(a,2)
contains
subroutine work(x,n)
integer,intent(in)::n
character(0),intent(out)::x(n)
x='ignored'
print *,len(x),size(x)
end subroutine
end program
