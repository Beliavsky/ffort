program p
implicit none
character(:),allocatable::s
allocate(character(6)::s)
write(s,'(i3)') 42
if(s/=' 42   '.or.len(s)/=6) error stop 1
end program
