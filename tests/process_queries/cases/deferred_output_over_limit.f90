program p
implicit none
character(:),allocatable::v
allocate(character(65537)::v)
call get_command_argument(0,v)
end program
