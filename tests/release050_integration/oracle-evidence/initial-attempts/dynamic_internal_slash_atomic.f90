program p

implicit none
character(8)::s(2)
character(12)::fmt
fmt='(i0,/)'
write(*,'(a)',advance='no')'SAFE'
write(s(2),fmt)maskr(2)
end program
