program main
implicit none
integer::i,a(3)
character(5)::s
s="1 2 3"
read(s,*) (a(i),i=1,3)
end program
