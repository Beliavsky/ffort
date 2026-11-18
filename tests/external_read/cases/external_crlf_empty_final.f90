program p
implicit none
integer::u,stat
character(4)::line
u=27
read(u,'(a)')line
if(line/='ab')stop 1
read(u,'(a)')line
if(line/=' ')stop 2
read(u,'(a)')line
if(line/='end')stop 3
read(u,'(a)',iostat=stat)line
if(stat>=0)stop 4
print '(a)', "OK"
end program
