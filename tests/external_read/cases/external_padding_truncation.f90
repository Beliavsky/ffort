program p
implicit none
integer::u,stat
character(4)::line
u=27
read(u,'(a)',iostat=stat)line
if(stat/=0.or.line/='abcd')stop 1
read(unit=u,fmt='( A )',iostat=stat)line
if(stat/=0.or.line/='xy  ')stop 2
print '(a)', "OK"
end program
