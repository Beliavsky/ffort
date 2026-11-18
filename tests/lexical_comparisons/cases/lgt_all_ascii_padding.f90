program p
implicit none
integer::i,c
c=0
do i=0,127
if(lgt("",achar(i)))c=c+1
enddo
print *,c
end program
