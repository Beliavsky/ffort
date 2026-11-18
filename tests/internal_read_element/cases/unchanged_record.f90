program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines="untouched"
lines(2)="23"
read(lines(2),*)n
if(n/=23.or.lines(2)/="23".or.lines(1)/="untouched".or.lines(3)/="untouched")stop 1
print '(a)', "OK"
end program
