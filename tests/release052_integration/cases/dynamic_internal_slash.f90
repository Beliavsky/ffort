program main
implicit none
character(2)::x(2)
character(8)::dest(2)
character(12)::fmt
x=['ab','cd']
dest='KEEP'
fmt='(a2,/,a2)'
write(*,'(a)',advance='no')'SAFE'
write(dest(2),fmt)x([2,1])
print '(a)',dest
end program
