program p
implicit none
character(2)::a(3,2)
integer(8)::s(2)
character(2)::b
a=reshape(['A ','BB',' C','D ',' E','F '],[3,2])
s=[1_8,-2_8]
b='? '
write(*,'(*(a,:,"|"))')eoshift(boundary=b,dim=1_8,shift=s,array=a)
end program
