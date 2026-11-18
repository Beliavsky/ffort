program p
implicit none
character(10)::unit
integer::read,stat
unit='19'
read=0
read(unit,*,iostat=stat) read
if(stat/=0.or.read/=19) stop 1
print *,1
end program
