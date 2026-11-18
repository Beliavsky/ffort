program main
implicit none
integer::i
integer::a(2,2,2)
a=1
a(2,1,1)=2
a(1,2,1)=3
a(2,2,1)=4
a(1,1,2)=5
a(2,1,2)=6
a(1,2,2)=7
a(2,2,2)=8
print *, (a,i=1,2)
end program
