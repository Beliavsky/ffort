program main
implicit none
character(4)::a(0)
call work(a,0)
print *, 'PASS'
contains
subroutine work(x,n)
character(*),intent(in)::x(:)
integer,intent(in)::n
character(len=len(x(1/n)))::y
y='test'
if(y/='test') error stop 1
end subroutine
end program
