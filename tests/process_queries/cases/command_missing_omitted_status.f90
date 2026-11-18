program p
implicit none
character(4)::v
call get_command_argument(1,v)
write(*,'(A)') '['//v//']'
end program
