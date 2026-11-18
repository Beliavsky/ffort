program p
implicit none
write(*,'(*(a,tl1,a))',advance='no') 'abc','X','def','Y'
write(*,'(t2,a)') '!'
end program
