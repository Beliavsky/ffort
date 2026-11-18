program p

implicit none
integer::n
character(8)::s(2)
n=33
write(*,'(a)',advance='no')'SAFE'
write(s(2),'(z8.8)')maskr(n)
end program
