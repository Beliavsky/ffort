program main
implicit none
character(12)::s
write(s,'(2("[",2(i2),"]"))') [1,2,3,4]
if(s/='[ 1 2][ 3 4]') error stop 'mismatch'
print '(a)',s
end program
