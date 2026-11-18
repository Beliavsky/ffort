program main
implicit none
character(0)::a(2)
a=''
call work(a)
print *, 'PASS'
contains
subroutine work(x)
character(*),intent(in)::x(:)
character(len=len(x(1)))::y
y='ignored'
if(len(y)/=0) error stop 1
end subroutine
end program
