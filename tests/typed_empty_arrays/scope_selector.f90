program p
implicit none
integer,parameter::k=4
call f()
if(kind([integer(k)::])/=4) error stop 1
print *, 'PASS'
contains
subroutine f()
integer,parameter::k=8
if(kind([integer(k)::])/=8) error stop 2
end subroutine
end program
