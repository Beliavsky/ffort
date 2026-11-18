program p
implicit none
write(*,'(2(i0,1x))')size(eoshift([integer::],1)),size(eoshift([character(2)::],0))
end program
