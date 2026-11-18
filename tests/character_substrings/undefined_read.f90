program test
implicit none
character(3)::s
if(s(1:2)=='') error stop 1
end program
