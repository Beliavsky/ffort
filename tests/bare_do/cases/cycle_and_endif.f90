program p
implicit none
integer::i,j,n
n=0
j=0
do
n=n+1
if(n<3) cycle
j=j+n
if(n==5) then
exit
endif
enddo
print *,n,j
end program
