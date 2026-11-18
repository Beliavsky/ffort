program p
implicit none
integer::a(5),b(5)
a=[10,20,30,40,50]
if(any(cshift(a,0)/=a)) error stop 1
if(any(cshift(a,5)/=a)) error stop 2
if(any(cshift(a,-10)/=a)) error stop 3
if(any(cshift(a,12)/=[30,40,50,10,20])) error stop 4
if(any(cshift(a,-12)/=[40,50,10,20,30])) error stop 5
b=cshift(array=a,shift=2,dim=1)
if(any(b/=[30,40,50,10,20])) error stop 6
print *, "PASS"
end program
