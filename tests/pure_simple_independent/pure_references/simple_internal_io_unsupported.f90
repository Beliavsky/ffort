program purity_test
implicit none

print *,compute(4)
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
character(len=8)::buffer
write(buffer,"(I8)") xx
rr=xx
end function compute

end program
