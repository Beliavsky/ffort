program p
implicit none
integer::u,stat
character(4)::line
u=27
read(u,'(a)',iostat=stat)line
if(stat>=0)stop 1
print '(a)', "OK"
end program
