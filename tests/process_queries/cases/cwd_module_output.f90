module m
implicit none
character(256)::v
end module
program p
use m
implicit none
call getcwd(v)
end program
