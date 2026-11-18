program main
implicit none
logical::b(2,2),z(0,2)
character(5)::s(2,2),e(0,2)
character(2)::sub(2,2)
b=.true.
s='ababa'
sub='ba'
call find(s,sub)
call find(s,sub,b)
call find(e,e,z)
call find(e,e)
print *, 'PASS'
contains
subroutine find(s,sub,b)
character(*),intent(in)::s(:,:),sub(:,:)
logical,optional,intent(in)::b(:,:)
if(present(b)) then
if(any(index(s,'ba',b)/=4)) error stop 1
if(any(index('ababa',sub,b)/=4)) error stop 2
else
if(any(index(s,'ba',b)/=2)) error stop 3
if(any(index('ababa',sub,b)/=2)) error stop 4
end if
end subroutine
end program
