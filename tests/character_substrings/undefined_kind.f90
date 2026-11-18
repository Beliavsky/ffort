program test
implicit none
character(3)::s
integer::i,j
if(kind(s(i:j))/=1) error stop 1
print '(a)','kind'
end program
