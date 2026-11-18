program p

implicit none
character(8)::s(1)
write(*,'(a)',advance='no')'P:'
write(s(1),'(b8.8,t3,a)')maskr(4),'XY'
print '(a)',s(1)
end program
