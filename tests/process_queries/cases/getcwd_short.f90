program p
implicit none
character(1)::c
integer::s
c='x'
call getcwd(c,s)
if(s==0) error stop 1
write(*,'(A)') '['//c//']'
end program
