program p
implicit none
integer::i,j,c
c=0
do i=0,127
do j=0,127
if(lgt(achar(i),achar(j)))c=c+1
enddo
enddo
print *,c
end program
