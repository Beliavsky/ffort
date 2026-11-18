program p
implicit none
write(*,'(a,t2,a,:,tr5,"tail")',advance='no') 'abc','X'
write(*,'(t2,a)') '!'
end program
