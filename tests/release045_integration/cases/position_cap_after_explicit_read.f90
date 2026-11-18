program p
implicit none
integer::u
character(8)::line
u=27
read(u,'(a)')line
write(*,'(a)',advance='no')trim(line)
print '(t65536,a)','X'
end program
