program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines(2)="17"
read(lines(2),*) n
if(n/=17) stop 1
print '(a)', "OK"
end program
