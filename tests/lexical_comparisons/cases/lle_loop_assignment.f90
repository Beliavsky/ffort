program p
implicit none
character::a(3)
logical::x(3)
integer::i
a=['a','b','c']
do i=1,4
x=lle(a,'b')
enddo
print *,x
end program
