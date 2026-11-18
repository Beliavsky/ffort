program p
implicit none
write(*,'(i0)')eoshift(4)
contains
integer function eoshift(x)
integer,intent(in)::x
eoshift=x+3
end function
end program
