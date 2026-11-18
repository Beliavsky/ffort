program p
implicit none
integer::u
character(0)::zero
character(4)::line
u=27
read(u,'(a)')zero
read(u,'(a)')line
if(line/='next')stop 1
print '(a)', "OK"
end program
