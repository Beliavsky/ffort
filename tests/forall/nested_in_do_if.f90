program p
implicit none
integer::a(3),i,j
a=0
do j=1,2
if(j==1) then
forall(i=1:3) a(i)=i
else
forall(i=1:3) a(i)=a(4-i)
endif
enddo
print *,a
end program
