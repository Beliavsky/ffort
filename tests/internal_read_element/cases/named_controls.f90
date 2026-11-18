program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines(2)="37"
read(unit=lines(2),fmt=*,iostat=ios)n
if(n/=37.or.ios/=0)stop 1
print '(a)', "OK"
end program
