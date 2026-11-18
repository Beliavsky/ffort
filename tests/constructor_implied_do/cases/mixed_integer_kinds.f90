program main
implicit none
integer::i
integer(8)::a(6)
a=[(i,int(i,8),i=1,3)]
end program
