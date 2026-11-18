program main
implicit none
character(2)::x(2)
character(8)::dest(2)
x(1)='ab'
dest='KEEP'
write(*,'(a)',advance='no')'SAFE'
write(dest(2),'(a)')x([1,2])
print '(a)',dest
end program
