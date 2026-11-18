program main
implicit none
character(6)::a(2)
call work(a)
if(any(a/='done  ')) error stop 1
print *, 'PASS'
contains
subroutine work(x)
character(*),intent(out)::x(:)
character(len=len(x(1)))::y
y='done'
x=y
end subroutine
end program
