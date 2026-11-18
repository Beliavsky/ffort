program p
implicit none
character(0)::c
integer::s
call getcwd(c,s)
if(s==0) error stop 1
write(*,'(A)') '['//c//']'
end program
