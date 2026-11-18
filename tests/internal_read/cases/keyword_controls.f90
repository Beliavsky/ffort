program p
implicit none
character(10)::text
integer::n,stat
text='14'
read(unit=text,fmt=*,iostat=stat) n
if(stat/=0.or.n/=14) stop 1
print *,1
end program
