program p
implicit none
character(256)::c
integer::s
call getcwd(status=s,count=c)
if(s/=0) error stop 1
write(*,'(A)') trim(c)
end program
