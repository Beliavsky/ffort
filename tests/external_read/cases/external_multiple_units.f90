program p
implicit none
integer(8)::u
character(4)::line
u=27
read(u,'(a)')line
if(line/='left')stop 1
u=28
read(u,'(a)')line
if(line/='rght')stop 2
u=27
read(u,'(a)')line
if(line/='more')stop 3
print '(a)', "OK"
end program
