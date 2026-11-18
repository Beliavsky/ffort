program p
implicit none
integer::i
character(24)::fmt
fmt='(*(a))'
write(*,'(a)',advance='no')repeat('x',65535)
write(*,fmt,advance='no')('z',i=1,2)
end program
