implicit none
integer::i,n
i=0
n=0
do while(i<5)
i=i+1
if(mod(i,2)==0) cycle
n=n+i
end do
print "(i0)",n
end
