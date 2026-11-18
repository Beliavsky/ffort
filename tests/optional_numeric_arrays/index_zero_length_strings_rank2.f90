program main
implicit none
character(0)::s(2,2)
logical::b(2,2)
s=''
b=.true.
call f(s)
call f(s,b)
print *, 'PASS'
contains
subroutine f(s,b)
character(*),intent(in)::s(:,:)
logical,optional,intent(in)::b(:,:)
if(any(index(s,'a',b)/=0)) error stop 1
if(any(index(s,'',b)/=1)) error stop 2
end subroutine
end program
