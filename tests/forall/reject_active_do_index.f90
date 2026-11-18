program p
implicit none
integer::i,a(2)
do i=1,2
forall(i=1:2) a(i)=i
enddo
end program
