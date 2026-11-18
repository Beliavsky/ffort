program main
implicit none
integer(8)::lo,hi
hi=huge(0_8)
lo=-hi
write(*,'(i0)')dim(lo,hi)
end program
