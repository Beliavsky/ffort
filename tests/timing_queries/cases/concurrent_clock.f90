program test
implicit none
integer::i,c
do concurrent(i=1:2)
call system_clock(c)
end do

end program
