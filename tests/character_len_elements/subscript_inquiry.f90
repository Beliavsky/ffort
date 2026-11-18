program main
implicit none
character(3)::a(2,2)
a='abc'
call work(a,2)
print *, 'PASS'
contains
subroutine work(x,n)
integer,intent(in)::n
character(*),intent(in)::x(:,:)
character(len=len(string=x(max(1,n-1),min(n,2)))+1)::y
y='ok'
if(len(y)/=4.or.y/='ok  ') error stop 1
end subroutine
end program
